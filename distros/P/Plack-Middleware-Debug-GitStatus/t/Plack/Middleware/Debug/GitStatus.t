use Test::Most;
use Test::MockObject::Extends;
use Test::MockObject;

BEGIN {
    use_ok( 'Plack::Middleware::Debug::GitStatus' );
}

if ( $ARGV[ 0 ] ) {
    no strict 'refs';
    &{$ARGV[ 0 ]}();
    done_testing;
    exit 0;
}


test_render_info();
test_run();

done_testing;


sub get_object {
    return Test::MockObject::Extends->new( 'Plack::Middleware::Debug::GitStatus' );
}

sub test_render_info {
    can_ok 'Plack::Middleware::Debug::GitStatus', 'render_info';
    my $obj = get_object;

    my $html = $obj->render_info( { error => 'fake error' } );
    like $html, qr|^<table>.+</table>$|s, 'the table is there';
    like $html, qr|<td>fake error</td>|, 'our fake error message is there';

    my @info_elements = qw/ current_branch status date author sha_1 message /;
    my $fake_info = {};
    foreach ( @info_elements ) {
        $fake_info->{ $_ } = 'fake-' . $_;
    }
    $html = $obj->render_info( $fake_info );
    foreach my $value ( @info_elements ) {
        like $html, qr|<([^>]+)>$fake_info->{ $value }</\1>|, "$value is in html output";
    }
    unlike $html, qr|href="|, 'no gitweb url, no href';

    $obj->mock( gitweb_url => sub { 'the_gitweb_url_%s_' } );
    $html = $obj->render_info( $fake_info );
    like $html, qr|href="the_gitweb_url_fake-sha_1_"|, 'gitweburl rendered correctly';
}

sub test_run {
    can_ok 'Plack::Middleware::Debug::GitStatus', 'run';
    my $obj = get_object;
    $obj->mock( get_git_info => sub { return 'fake-branch', 'fake-info' } );
    $obj->mock( render_info  => sub { return 'mock content' } );

    my $mock_panel = Test::MockObject->new;
    my ( $title, $nav_title, $nav_subtitle, $content );
    $mock_panel->mock( title        => sub { $title        = $_[ 1 ] } );
    $mock_panel->mock( nav_title    => sub { $nav_title    = $_[ 1 ] } );
    $mock_panel->mock( nav_subtitle => sub { $nav_subtitle = $_[ 1 ] } );
    $mock_panel->mock( content      => sub { $content      = $_[ 1 ] } );

    my $app = $obj->run( undef, $mock_panel );
    isa_ok $app, 'CODE';
    ok $app->(), 'can call the returned code reference';
    is $title,        'GitStatus',             'title called correctly';
    is $nav_title,    'GitStatus',             'nav_title called correctly';
    is $nav_subtitle, 'On branch fake-branch', 'nav_subtitle called correctly';
    is $content,      'mock content',          'content called correctly';
}

