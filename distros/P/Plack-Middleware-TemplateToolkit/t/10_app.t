use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::TemplateToolkit;
use HTTP::Request;
use File::Spec;
use Plack::Middleware::ErrorDocument;
use Template;

BEGIN {
    use lib "t";
    require_ok "app_tests.pl";
}

my $root = File::Spec->catdir( "t", "root" );

my $app = Plack::Middleware::TemplateToolkit->new(
    INCLUDE_PATH => $root,
    POST_CHOMP   => 1
)->to_app();

$app = Plack::Middleware::ErrorDocument->wrap( $app, 404 => "$root/404.html" );

app_tests
    app   => $app,
    tests => [
    {   name    => 'Basic request',
        request => [ GET => '/index.html' ],
        content => 'Page value',
        headers => { 'Content-Type' => 'text/html', },
    },
    {   name    => 'Index request',
        request => [ GET => '/' ],
        content => 'Page value',
        headers => { 'Content-Type' => 'text/html', },
    },
    {   name    => '404request',
        request => [ GET => '/boom.html' ],
        content => '404-page[% path %]', # served by ::ErrorDocument, no template
        headers => { 'Content-Type' => 'text/html', },
        code    => 404
    },
    {   name    => 'MIME type by extension',
        request => [ GET => '/style.css' ],
        content => 'body { font-style: sans-serif; }',
        headers => { 'Content-Type' => 'text/css', },
    },
    {   name    => 'No extension',
        request => [ GET => '/noext' ],
        content => 'What am I?',
        headers => { 'Content-Type' => 'text/html', },
    },
    {   name    => 'broken template',
        request => [ GET => '/broken.html' ],
        content => qr/^file error - parse error/,
        headers => { 'Content-Type' => 'text/html', },
        code    => 500
    },
    {   name    => 'no request_vars by default',
        request => [ GET => '/req.html' ],
        content => 'R:,,',
        code    => 200
    }
    ];

app_tests
    app => Plack::Middleware::TemplateToolkit->new(
        INCLUDE_PATH => $root, POST_CHOMP => 1,
        path         => qr{^/ind},
    ),
    tests => [{
        name    => 'Basic request',
        request => [ GET => '/index.html' ],
        content => 'Page value',
        headers => { 'Content-Type' => 'text/html', },
    },{   
        name    => 'Unmatched request',
        request => [ GET => '/style.css' ],
        content => 'Not found', # default error message
        code    => 404,
    }];

app_tests
    app => Plack::Middleware::TemplateToolkit->new(
        INCLUDE_PATH => $root,
        PRE_PROCESS  => 'pre.html',
        POST_CHOMP   => 1
    )->to_app(),
    tests => [
    {   name    => 'Basic request with pre_process',
        request => [ GET => '/index.html' ],
        content => 'Included Page value',
        headers => { 'Content-Type' => 'text/html', },
    }
    ];

app_tests
    app => Plack::Middleware::TemplateToolkit->new(
        INCLUDE_PATH => $root,
        PROCESS      => 'process.html',
        POST_CHOMP   => 1
    )->to_app(),
    tests => [
    {   name    => 'Basic request with pre_process',
        request => [ GET => '/index.html' ],
        content => 'The Page value here',
        headers => { 'Content-Type' => 'text/html', },
    }
    ];

app_tests
    app => Plack::Middleware::TemplateToolkit->new(
        INCLUDE_PATH => $root,
        default_type => 'text/plain'
    )->to_app(),
    tests => [
    {   name    => 'Default MIME type',
        request => [ GET => '/noext' ],
        content => 'What am I?',
        headers => { 'Content-Type' => 'text/plain', },
    }
    ];

app_tests
    app => Plack::Middleware::TemplateToolkit->new(
        INCLUDE_PATH => $root,
        extension => 'html',
        request_vars => 'all',
    )->to_app(),
    tests => [
    {   name    => 'Forbidden extension',
        request => [ GET => '/style.css' ],
        content => 'Not found',
        headers => { 'Content-Type' => 'text/plain', },
        code    => 404
    },
    {   name    => 'all request_vars',
        request => [ GET => '/req.html?foo=bar' ],
        content => qr{^R:Plack::Request[^,]+,GET,bar}
    }
    ];

$app = Plack::Middleware::TemplateToolkit->new(
        INCLUDE_PATH => $root,
        vars => { foo => 'Hello', bar => ', world!' }
    );

# run twice to check that template does not modify vars
foreach (qw(1 2)) {
    app_tests  
        app => $app,    
        tests => [
        {   name    => 'Variables in templates',
            request => [ GET => '/vars.html' ],
            content => 'Hello, world!',
        }
        ];
}

my $template = Template->new( INCLUDE_PATH => $root );

$app = Plack::Middleware::TemplateToolkit->new(
        tt   => $template,
        vars => sub {
            my $req = shift;
            my $bar = $req->param('who');
            return { foo => 'Hi, ', bar => $bar };
        },
        request_vars => [qw(method parameters idontexist)],
    );

app_tests 
    app => $app,
    tests => [{   
        name    => 'Variables in templates',
        request => [ GET => '/vars.html?who=you' ],
        content => 'Hi, you',
    },
    {   name    => 'request_vars in addition',
        request => [ GET => '/req.html?foo=bar' ],
        content => qr{^R:HASH[^,]+,GET,bar}
    }
    ];

$app->vars( sub { return { request => undef } } );

app_tests app => $app->to_app(),
    tests => [
    {   name    => 'request_vars do not override vars',
        request => [ GET => '/req.html?foo=bar' ],
        content => 'R:,,'
    }
    ];

$app->vars( sub { die "sorry" } );
app_tests app => $app->to_app(),
    tests => [
    {   name    => 'vars method may die',
        request => [ GET => '/req.html?foo=bar' ],
        content => qr{^error setting template variables: sorry},
    },
    {   name    => 'vars method may die during error processing',
        request => [ GET => '/broken.html' ],
        content => qr{^error setting template variables: sorry},
    }
    ];


$app = Plack::Middleware::TemplateToolkit->new(
    INCLUDE_PATH => $root, POST_CHOMP => 1 );

app_tests 
    app => builder {
        enable sub { my $app = shift; sub { 
            my $env = shift;
            # test for empty PATH_INFO
            $env->{PATH_INFO} = '' if $env->{PATH_INFO} eq '/index.html'; 
            $app->($env);
        } };
        $app;
    },
    tests => [{
        name    => 'use as plain app',
        request => [ GET => '/index.html' ],
        content => 'Page value',
        code    => 200,
    }];

app_tests 
    app => builder {
        enable sub { my $app = shift; sub { 
            my $env = shift;
            $env->{'tt.vars'} = { bar => 'Do' };
            $app->($env);
        } };
        $app;
    },
    tests => [{
        name    => 'with mixed variable sources',
        request => [ GET => '/vars.html?foo=Ho' ],
        content => 'HoDo',
        code    => 200,
    }];

done_testing;
