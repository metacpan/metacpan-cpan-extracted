#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Template::Stencil;
use Template::Stencil::PSGI;

sub psgi_env {
    my ($path) = @_;
    return {
        REQUEST_METHOD    => 'GET',
        PATH_INFO         => $path,
        SCRIPT_NAME       => '',
        SERVER_NAME       => 'localhost',
        SERVER_PORT       => 5000,
        SERVER_PROTOCOL   => 'HTTP/1.1',
        'psgi.version'    => [1, 1],
        'psgi.url_scheme' => 'http',
        'psgi.errors'     => \*STDERR,
    };
}

# Drive the shipped example app in-process (no HTTP server needed).
{
    my $app = do './examples/plack.psgi';
    die "examples/plack.psgi: " . ($@ || $!) unless ref $app eq 'CODE';

    my $res = $app->(psgi_env('/'));
    is($res->[0], 200, 'status 200');
    my %h = @{ $res->[1] };
    like($h{'Content-Type'}, qr{text/html}, 'content type');
    my $body = join '', @{ $res->[2] };
    is($h{'Content-Length'}, length $body, 'content length matches');

    like($body, qr/<!doctype html>/,           'wrapper rendered');
    like($body, qr/<h1>STENCIL<\/h1>/,         'filter ran in header include');
    like($body, qr/hello, lnation/,            'conditional took user branch');
    like($body, qr/class="first"/,             'loop first class');
    like($body, qr/class="last"/,              'loop last class');
    like($body, qr/#10\/10: item 10/,          'loop metadata and trim filter');
    like($body, qr/<script src="app\.js">/,    'wrapper js loop');

    # Second request hits the template cache: no compiles, no stats.
    my $s0 = Template::Stencil::_stencil_stats();
    my $res2 = $app->(psgi_env('/'));
    my $s1 = Template::Stencil::_stencil_stats();
    is($s1->{compiles} - $s0->{compiles}, 0, 'second request: no compiles');
    is($s1->{stats} - $s0->{stats}, 0,
       'second request: no stat syscalls (stat_ttl -1)');
    is(join('', @{ $res2->[2] }), $body, 'stable output');
}

# The PSGI sugar module.
{
    my $view = Template::Stencil::PSGI->new(
        template_dir => 'examples/templates',
        wrapper      => 'wrapper.tmpl',
    );
    isa_ok($view->stencil, 'Template::Stencil', 'stencil accessor');

    my $res = $view->res('index', { title => 'T', items => [] }, 201,
                         [ 'X-Extra' => 'y' ]);
    is($res->[0], 201, 'res custom status');
    my %h = @{ $res->[1] };
    is($h{'X-Extra'}, 'y', 'extra headers appended');
    like(join('', @{ $res->[2] }), qr/nothing to show/, 'unless branch');

    my $app = $view->to_app({
        '/'       => [ 'index', sub { { title => 'R', items => [] } } ],
        '/plain'  => 'index',
    });
    is($app->(psgi_env('/'))->[0], 200, 'routed');
    like(join('', @{ $app->(psgi_env('/'))->[2] }), qr/<h1>R<\/h1>/,
         'route data callback ran');
    is($app->(psgi_env('/plain'))->[0], 200, 'bare template route');
    is($app->(psgi_env('/missing'))->[0], 404, '404 fallthrough');
}

done_testing;
