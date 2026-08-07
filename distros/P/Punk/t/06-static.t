#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Temp ();

# Static file serving through the mount table: content types, HEAD,
# If-Modified-Since 304, traversal defense, and mount precedence.

my $dir = File::Temp->newdir;
{
    open my $fh, '>', "$dir/app.css" or die $!;
    print $fh "body { color: red }\n";
    close $fh;
    mkdir "$dir/sub";
    open $fh, '>', "$dir/sub/x.txt" or die $!;
    print $fh "nested";
    close $fh;
}

{
    package StaticApp;
    use Punk;
    get '/static/:x' => sub { $_[0]->text('route wins? no') };
    package main;
    StaticApp::static('/static' => "$dir");
}

my $app = StaticApp->to_app;

{
    my $r = hit($app, path => '/static/app.css');
    is($r->[0], 200, 'file serves');
    my %h = @{ $r->[1] };
    is($h{'Content-Type'}, 'text/css; charset=utf-8', 'css content type');
    ok($h{'Content-Length'} > 0, 'content length set');
    ok($h{'Last-Modified'}, 'last modified set');
    local $/;
    my $body = ref $r->[2] eq 'ARRAY' ? $r->[2][0] : do {
        my $fh = $r->[2]; <$fh> };
    like($body, qr/color: red/, 'file body');

    my $again = hit($app, path => '/static/app.css',
        env => { HTTP_IF_MODIFIED_SINCE => $h{'Last-Modified'} });
    is($again->[0], 304, 'exact If-Modified-Since is a 304');
}
is(hit($app, path => '/static/sub/x.txt')->[0], 200, 'nested paths serve');
is(hit($app, path => '/static/nope.css')->[0], 404, 'missing file 404s');
is(hit($app, path => '/static/../secret')->[0], 404,
    'dotdot is a 404, never traversal');
{
    my $r = hit($app, method => 'HEAD', path => '/static/app.css');
    is($r->[0], 200, 'HEAD serves');
    is_deeply($r->[2], [''], 'HEAD body empty');
}
{
    my $r = hit($app, method => 'POST', path => '/static/app.css');
    is($r->[0], 405, 'POST to static is a 405');
}

# a mount takes precedence over a dynamic route on the same prefix
is(hit($app, path => '/static/app.css')->[0], 200,
    'mount beats the /static/:x dynamic route');

# ---- generic PSGI mounts -----------------------------------------------------
{
    package MountApp;
    use Punk;
    get '/x' => sub { $_[0]->text('punk') };
    package main;
    MountApp::mount('/legacy' => sub {
        my ($env) = @_;
        [ 200, ['Content-Type' => 'text/plain',
                'Content-Length' => length($env->{PATH_INFO})],
          [ $env->{PATH_INFO} ] ];
    });
    my $mapp = MountApp->to_app;
    is(hit($mapp, path => '/legacy/deep/path')->[2][0], '/deep/path',
        'mounted app sees the stripped PATH_INFO');
    is(hit($mapp, path => '/legacy')->[2][0], '/',
        'the bare prefix maps to /');
    is(hit($mapp, path => '/legacyish')->[0], 404,
        'prefix matching is per segment');
}

# ---- missing directory croaks at boot ----------------------------------------
{
    package BadDir;
    use Punk;
    package main;
    BadDir::static('/s' => '/no/such/dir/punk');
    my $err = '';
    eval { BadDir->to_app } or $err = $@;
    like($err, qr/not a directory/, 'bad static dir croaks at to_app');
}

done_testing();
