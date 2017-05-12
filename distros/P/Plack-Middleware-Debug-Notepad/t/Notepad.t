use Test::Most;
use Test::MockObject::Extends;
use Test::MockModule;
use Plack::Middleware::Debug::Panel;
use File::Tempdir;

BEGIN {
    use_ok( 'Plack::Middleware::Debug::Notepad' );
}

test_call();
test_run();
test_save_markdown();

done_testing;


sub get_object {
    return Plack::Middleware::Debug::Notepad->new;
}

sub test_call {
    can_ok 'Plack::Middleware::Debug::Notepad', 'call';

    subtest 'b0rked request' => sub {
        my $obj = get_object;
        dies_ok
            { $obj->call( {} ) }
            'dies somewhere in Debug::Base';

        dies_ok
            { $obj->call( {
                REQUEST_METHOD => 'POST',
                QUERY_STRING => 'plack_middleware_debug_notepad'
              } )
            }
            'request not captured, wrong query string';
    };

    subtest 'GET - retrieve notpad content' => sub {
        my $obj = Test::MockObject::Extends->new( get_object );
        $obj->mock( get_markdown => sub { 'hello world' } );
        my $result = $obj->call( {
            REQUEST_METHOD => 'GET',
            QUERY_STRING   => 'foo&__plack_middleware_debug_notepad__=bar'
        } );
        is $result->[ 0 ], 200, 'returns status 200';
        is $result->[ 1 ]->[ 0 ], 'Content-Type', 'sets a Content-Type';
        is $result->[ 1 ]->[ 1 ], 'text/html', 'to text/html';
        is $result->[ 2 ]->[ 0 ], 'hello world', 'the result of get_markdown() makes up the respnose body';
    };

    subtest 'POST - save content' => sub {
        my $obj = Test::MockObject::Extends->new( get_object );
        $obj->mock( save_markdown => sub { 'save_markdown result' } );
        my $result = $obj->call( {
            REQUEST_METHOD => 'POST',
            QUERY_STRING => 'foo&__plack_middleware_debug_notepad__=bar'
        } );
        is $result, 'save_markdown result', 'returns the result of save_markdown';
    };
}

sub test_run {
    can_ok 'Plack::Middleware::Debug::Notepad', 'run';
    my $obj = get_object;

    my $panel = Plack::Middleware::Debug::Panel->new;
    $panel->dom_id( 'the-dom_id' );

    my $mocker = Test::MockModule->new( 'Plack::Middleware::Debug::Notepad' );
    $mocker->mock( get_notepad_content => sub { 'generated panel content' } );
    my $result = $obj->run( {}, $panel );
    isa_ok $result, 'CODE';
    ok ! $panel->title, 'title is not yet set';
    ok ! $panel->nav_title, 'nav_title is not yet set';
    ok ! $panel->nav_subtitle, 'nav_subtitle is not yet set';
    ok ! $panel->content, 'content is not yet set';

    $result->();
    is $panel->title, 'Notepad', 'title is correctly set';
    is $panel->nav_title, 'Notepad', 'nav_title is correctly set';
    is $panel->nav_subtitle, 'things to keep in mind', 'nav_subtitle is correctly set';
    is $panel->content, 'generated panel content', 'content is correctly set';
}

sub test_save_markdown {
    can_ok 'Plack::Middleware::Debug::Notepad', 'save_markdown';

    my $tmp_dir = File::Tempdir->new;
    my $store = $tmp_dir->name . '/notepad_file.tmp';

    my $obj = get_object;
    $obj->notepad_file( $store );

    my $md = "# this\n## is just\n### a test\n";
    my $mock_request = Test::MockModule->new(
        'Plack::Request'
    );
    $mock_request->mock( param => sub { $md } );

    my $result = $obj->save_markdown( {} );

    is $result->[ 0 ], 200, 'returns status 200';
    is $result->[ 1 ]->[ 1 ], 'text/html', 'content type seems ok';

    my $expected_html = '<h1>this</h1>

<h2>is just</h2>

<h3>a test</h3>
';
    is $result->[ 2 ]->[ 0 ], $expected_html, 'correct html returned';
    ok -e $store, 'store file exists';

    open my $fh, '<', $store;
    local $/;
    my $md_got = <$fh>;
    is $md_got, $md, 'markdown correctly saved';

    $md_got = $obj->get_markdown;
    is $md_got, $md, 'markdown correctly saved and retrieved';

    unlink $store;
}

