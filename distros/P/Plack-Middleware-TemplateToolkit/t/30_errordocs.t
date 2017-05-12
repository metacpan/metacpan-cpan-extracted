use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::TemplateToolkit;
use HTTP::Request;
use File::Spec;
use Plack::Builder;

BEGIN {
    use lib "t";
    require_ok "app_tests.pl";
}

my $root = File::Spec->catdir( "t", "root" );

my $app = Plack::Middleware::TemplateToolkit->new(
    INCLUDE_PATH => $root, POST_CHOMP   => 1,
    404  => '404.html',
    500  => '500.html',
    200  => 'ignore_this',
);

# must not die, even if prepare_app has not been called
my ($err,$tpl) = $app->process_error;
is $tpl, undef, 'no error document';

$err = $app->process_error( 424, undef, 'text/html' );
is_deeply $err, [424,['Content-Type'=>'text/html'],
                     ['Failed Dependency']], 'process_error 424 (unprepared)';

$err = $app->process_error;
is_deeply $err, [500,['Content-Type'=>'text/plain'],
                     ['Internal Server Error']], 'process_error 500 (unprepared)';

$app->prepare_app; # in general this should have been called before

($err,$tpl) = $app->process_error;

$err = $app->process_error;
is_deeply $err, [500,['Content-Type'=>'text/html'],
                     ['Server error: Internal Server Error']], 'process_error 500';

($err,$tpl) = $app->process_error( 500, 'Sorry!' );
is $tpl, '500.html', 'got 500.html';
is_deeply $err, [500,['Content-Type'=>'text/html'],
                     ['Server error: Sorry!']], 'process_error 500 with message';

($err,$tpl) = $app->process_error( 404 );
is $tpl, '404.html', 'got 404.html';
is_deeply $err, [404,['Content-Type'=>'text/html'],
                     ['404-page']], 'process_error 404';

app_tests
    app => $app,
    tests => [
    {   name    => 'Basic request',
        request => [ GET => '/index.html' ],
        content => 'Page value',
        headers => { 'Content-Type' => 'text/html', },
        code    => 200
    },
    {   name    => '404 error template',
        request => [ GET => '/boom.html' ],
        content => '404-page/boom.html',
        headers => { 'Content-Type' => 'text/html', },
        code    => 404,
        logged  => []
    },
    {   name    => '500 error template',
        request => [ GET => '/broken.html' ],
        content => qr/^Server error: file error - parse error/,
        headers => { 'Content-Type' => 'text/html', },
        code    => 500,
        logged  => [ { level => 'warn' } ],
    }
    ];

app_tests
    app => Plack::Middleware::TemplateToolkit->new(
        INCLUDE_PATH => $root,
        POST_CHOMP   => 1,
        404  => '404_missing.html',
        500  => '500.html',
    ),
    tests => [
    {   name    => '404 error template missing but we have 500 template',
        request => [ GET => '/boom.html' ],
        content => 'Server error: file error - 404_missing.html: not found',
        headers => { 'Content-Type' => 'text/html', },
        code    => 500,
        logged  => [ { level => 'warn' } ],
    }
    ];

app_tests
    app => Plack::Middleware::TemplateToolkit->new(
        INCLUDE_PATH => $root,
        404  => '404_missing.html',
        500  => '500_missing.html',
    ),
    tests => [
    {   name => '404 error template missing and 500 error template missing',
        request => [ GET => '/boom.html' ],
        content => 'file error - 500_missing.html: not found',
        headers => { 'Content-Type' => 'text/html', },
        code    => 500,
        logged => [ { level => 'warn' } ],
    },
    {   name    => '500 error template missing',
        request => [ GET => '/broken.html' ],
        content => 'file error - 500_missing.html: not found',
        headers => { 'Content-Type' => 'text/html', },
        code    => 500,
        logged  => [
            {   level   => 'warn',
                message => qr/^file error - parse error - broken.html/
            }
        ]
    }
    ];

app_tests
    app => Plack::Middleware::TemplateToolkit->new(
        INCLUDE_PATH => $root, 
        POST_CHOMP => 1,
        404  => '404.html',
        path => sub { shift =~ qr{^/ind} },
    ),
    tests => [{
        name    => 'Path checked via sub',
        request => [ GET => '/index.html' ],
        content => 'Page value',
    },{   
        name    => 'Unmatched request, 404 as template',
        request => [ GET => '/style.css' ],
        code    => 404,
        content => '404-page/style.css',
    }];


done_testing;
