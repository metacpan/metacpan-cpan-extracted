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

# ---- validators and ranges (the send_file core, since 0.13) ------------------
{
    my $body = "0123456789" x 10;
    open my $fh, '>', "$dir/data.bin" or die $!;
    binmode $fh;
    print {$fh} $body;
    close $fh;

    my $r = hit($app, path => '/static/data.bin');
    my %h = @{ $r->[1] };
    like($h{ETag}, qr/^"[0-9a-f]+-64"$/,
        'a strong hex ETag, sized like the file');
    is($h{'Accept-Ranges'}, 'bytes', 'ranges are advertised');

    my $etag = $h{ETag};
    is(hit($app, path => '/static/data.bin',
           env => { HTTP_IF_NONE_MATCH => $etag })->[0], 304,
        'If-None-Match answers 304');
    is(hit($app, path => '/static/data.bin',
           env => { HTTP_IF_NONE_MATCH => '"stale"' })->[0], 200,
        'a stale tag serves the file');

    # the ETag is stable across requests
    my %h2 = @{ hit($app, path => '/static/data.bin')->[1] };
    is($h2{ETag}, $etag, 'the ETag is stable across requests');

    $r = hit($app, path => '/static/data.bin',
             env => { HTTP_RANGE => 'bytes=10-19' });
    is($r->[0], 206, 'a range serves partial content');
    %h = @{ $r->[1] };
    is($h{'Content-Range'},  'bytes 10-19/100', 'with Content-Range');
    is($h{'Content-Length'}, 10,                'and the range length');
    {
        my @chunks;
        my $b = $r->[2];
        while (defined(my $c = $b->getline)) { push @chunks, $c }
        $b->close;
        is(join('', @chunks), '0123456789', 'and exactly those bytes');
    }

    $r = hit($app, path => '/static/data.bin',
             env => { HTTP_RANGE => 'bytes=999-' });
    is($r->[0], 416, 'past the end is a 416');
    %h = @{ $r->[1] };
    is($h{'Content-Range'}, 'bytes */100', 'with the unsatisfied form');

    is(hit($app, path => '/static/data.bin',
           env => { HTTP_RANGE => 'bytes=0-1,5-9' })->[0], 200,
        'a multi-range request legally gets the whole file');
}

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
