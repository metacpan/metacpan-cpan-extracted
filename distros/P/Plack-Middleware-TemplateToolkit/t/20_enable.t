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
my $err = sub {
    [ 500, [ "Content-type" => "text/plain" ], ["Server hit the bottom"] ];
};

app_tests
    name => 'pass_though',
    app  => builder {
    enable "Plack::Middleware::TemplateToolkit",
        INCLUDE_PATH => $root,
        POST_CHOMP   => 1,
        pass_through => 1;
    $err;
    },
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
        content => 'Server hit the bottom',
        headers => { 'Content-Type' => 'text/plain', },
    }
    ];

app_tests app => builder {
    enable "Plack::Middleware::TemplateToolkit",
        INCLUDE_PATH => $root,
        POST_CHOMP   => 1,
        default_type => "text/plain";
    $err;
},
    tests => [
    {   name    => '404request',
        request => [ GET => '/boom.html' ],
        content => 'file error - boom.html: not found',
        headers => { 'Content-Type' => 'text/plain', },
    }
    ];

done_testing;
