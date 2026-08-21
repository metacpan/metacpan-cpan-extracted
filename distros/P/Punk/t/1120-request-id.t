#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Time::HiRes ();
use Punk ();

# Punk::Plugin::RequestId.
#
# This plugin was documented before it existed: Punk.pm's SYNOPSIS has opened
# with `plugin 'RequestId';` all along, its config walkthrough lists it, and
# Punk::Plugin's SYNOPSIS uses it as the worked example of the whole plugin
# API. Copying any of the three got "Can't locate Punk/Plugin/RequestId.pm".

my $dir = File::Temp::tempdir(CLEANUP => 1);
mkdir "$dir/static";
open my $sfh, '>', "$dir/static/f.txt" or die $!;
print $sfh 'static body';
close $sfh;

sub env_for {
    my ($method, $path) = @_;
    return {
        REQUEST_METHOD => $method,
        PATH_INFO      => $path,
        QUERY_STRING   => '',
        'psgi.input'   => undef,
        'psgi.errors'  => \*STDERR,
    };
}
sub hdr {
    my ($res, $name) = @_;
    $name ||= 'X-Request-Id';
    my %h = @{ $res->[1] };
    return $h{$name};
}

# ---- the id itself -----------------------------------------------------------
{
    my $id = Punk::Plugin::RequestId->_mint;
    like($id, qr/\A[0-9a-f]{32}\z/, 'a 32-character lowercase hex id');
    is(substr($id, 12, 1), '7', 'UUID version 7');
    like(substr($id, 16, 1), qr/[89ab]/, 'and the RFC 9562 variant bits');

    my %seen;
    $seen{ Punk::Plugin::RequestId->_mint }++ for 1 .. 10_000;
    is(scalar keys %seen, 10_000, '10,000 ids, no repeats');
}

# Sorting by id sorts by TIME, which is the reason for paying 12ns over a
# plain random id. Across milliseconds, because within one the tail is random
# and that is the resolution the format offers - asserting more than that
# would be asserting something UUIDv7 does not promise.
{
    my @ids;
    for (1 .. 5) {
        push @ids, Punk::Plugin::RequestId->_mint;
        Time::HiRes::sleep(0.002);
    }
    is_deeply(\@ids, [ sort @ids ],
        'ids minted in different milliseconds sort chronologically');
}

# ---- the SYNOPSIS, verbatim --------------------------------------------------
# Punk.pm's SYNOPSIS opens with this line. It was a croak for the whole life
# of the dist, so it is asserted rather than trusted from here on.
{
    my $ok = eval {
        package SynopsisApp;
        use Punk;
        plugin 'RequestId';
        get '/' => sub { $_[0]->text('ok') };
        1;
    };
    ok($ok, "Punk.pm's SYNOPSIS line runs: plugin 'RequestId'") or diag $@;
    ok(eval { SynopsisApp->to_app; 1 }, 'and the app compiles') or diag $@;
}

# ---- every response shape ----------------------------------------------------
# The assertion the design turns on. Punk's dispatcher has exits that never
# reach punk_finish_c - the house 404 and 405 among them - so an
# after_dispatch hook cannot see them. An id present on a 200 and missing on
# a 404 is missing exactly when somebody is trying to trace a 404.
{
    package ShapesApp;
    use Punk;

    plugin 'RequestId';

    get  '/ok'    => sub { $_[0]->text('ok') };
    get  '/boom'  => sub { die "kaboom\n" };
    post '/only'  => sub { $_[0]->text('posted') };
    static '/s'   => "$dir/static";
    mount '/psgi' => sub {
        [ 200, [ 'Content-Type' => 'text/plain' ], ['mounted'] ];
    };

    package main;
    my $app = ShapesApp->to_app;

    my @shapes = (
        [ 'a matched route',      'GET',  '/ok'        ],
        [ 'a 404',                'GET',  '/nowhere'   ],
        [ 'a 405',                'GET',  '/only'      ],
        [ 'a static file',        'GET',  '/s/f.txt'   ],
        [ 'a mounted PSGI app',   'GET',  '/psgi/x'    ],
        [ 'a handler that died',  'GET',  '/boom'      ],
    );

    for my $s (@shapes) {
        my ($what, $method, $path) = @$s;
        my $res = $app->(env_for($method, $path));
        like(hdr($res), qr/\A[0-9a-f]{32}\z/,
            "$what carries X-Request-Id (status $res->[0])")
            or diag "headers: @{$res->[1]}";
    }
}

# ---- the id the client sees is the id the handler had ------------------------
{
    package MatchApp;
    use Punk;
    plugin 'RequestId';
    get '/' => sub { $_[0]->text($_[0]->request_id) };

    package main;
    my $app = MatchApp->to_app;
    my $res = $app->(env_for('GET', '/'));
    is(hdr($res), $res->[2][0],
        '$c->request_id is the value the client receives - a header that did '
      . 'not match what the handler logged would be worse than no header');

    my $one = $app->(env_for('GET', '/'))->[2][0];
    my $two = $app->(env_for('GET', '/'))->[2][0];
    isnt($one, $two, 'and two requests get two different ids');
}

# ---- options -----------------------------------------------------------------
{
    package NoHeaderApp;
    use Punk;
    plugin 'RequestId' => { header => 0 };
    get '/' => sub { $_[0]->text($_[0]->request_id) };

    package main;
    my $res = NoHeaderApp->to_app->(env_for('GET', '/'));
    is(hdr($res), undef, 'header => 0 sends no header');
    like($res->[2][0], qr/\A[0-9a-f]{32}\z/,
        'but the id is still minted and still reachable - an application may '
      . 'want ids in its logs without putting them on the wire');
}

{
    package RenamedApp;
    use Punk;
    plugin 'RequestId' => { header => 'X-Correlation-Id' };
    get '/' => sub { $_[0]->text('ok') };

    package main;
    my $res = RenamedApp->to_app->(env_for('GET', '/'));
    like(hdr($res, 'X-Correlation-Id'), qr/\A[0-9a-f]{32}\z/,
        'the header can be renamed');
}

{
    my $err = do {
        local $@;
        eval {
            package BadHeaderApp;
            use Punk;
            plugin 'RequestId' => { header => "X-Bad\r\nInjected: 1" };
            get '/' => sub { };
            1;
        };
        $@;
    };
    like($err, qr/not a usable header name/,
        'a header name carrying CRLF is refused AT BOOT rather than written '
      . 'into a response, where it would split it');
}

# ---- two apps in one process ------------------------------------------------
# Two Punk apps under one Plack::Builder share a process. The first version
# held the header name in a C static, so whichever app registered LAST named
# the header for both - app A emitted X-B-Id. A per-app option that quietly
# stops being per-app is worse than one that was never offered.
{
    package AppOne;
    use Punk;
    plugin 'RequestId' => { header => 'X-A-Id' };
    get '/' => sub { $_[0]->text('a') };

    package AppTwo;
    use Punk;
    plugin 'RequestId' => { header => 'X-B-Id' };
    get '/' => sub { $_[0]->text('b') };

    package AppNone;
    use Punk;
    get '/' => sub { $_[0]->text('c') };

    package main;
    my $one  = AppOne->to_app;
    my $two  = AppTwo->to_app;
    my $none = AppNone->to_app;

    like(hdr($one->(env_for('GET','/')), 'X-A-Id'), qr/\A[0-9a-f]{32}\z/,
        'the first app uses ITS header name');
    like(hdr($two->(env_for('GET','/')), 'X-B-Id'), qr/\A[0-9a-f]{32}\z/,
        'and the second app uses its own, in the same process');
    is(hdr($one->(env_for('GET','/')), 'X-B-Id'), undef,
        "and the first app does not emit the second's header");

    my @names = grep { /-Id\z/i } do { my %h = @{ $none->(env_for('GET','/'))->[1] }; keys %h };
    is_deeply(\@names, [],
        'an app that never loaded the plugin gets no header and mints nothing '
      . '- the observers are process-wide, so this had to be checked');
}

# ---- across a real worker pool -----------------------------------------------
# Phase 0 proved this for the generator; this proves it through the plugin, on
# forked processes, which is where the entropy buffer would betray it. Filled
# once and inherited, every worker hands out the same bytes - and it looks
# perfectly random while doing it.
SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $workers = 4;
    my $per     = 500;
    pipe my $rd, my $wr or die "pipe: $!";

    # Mint one in the PARENT first, so the buffer is warm and inherited -
    # which is precisely the condition that makes a naive implementation
    # collide. A test that forked before touching the generator would pass
    # against the bug.
    Punk::Plugin::RequestId->_mint;

    my @pids;
    for (1 .. $workers) {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            close $rd;
            # syswrite, not print: a buffered handle shared across forked
            # children is its own source of lost and interleaved output.
            syswrite $wr, join('', map { Punk::Plugin::RequestId->_mint . "\n" }
                                       1 .. $per);
            close $wr;
            POSIX::_exit(0) if eval { require POSIX; 1 };
            exit 0;
        }
        push @pids, $pid;
    }
    close $wr;

    my %seen;
    my $lines = 0;
    while (my $line = <$rd>) {
        chomp $line;
        next unless length $line;
        $seen{$line}++;
        $lines++;
    }
    close $rd;
    waitpid $_, 0 for @pids;

    is($lines, $workers * $per,
        "all $workers workers reported their ids");
    is(scalar keys %seen, $lines,
        'EVERY id is unique across the pool - the entropy buffer is filled '
      . 'per process, not inherited from the parent that warmed it')
        or diag sprintf 'got %d distinct ids from %d', scalar keys %seen, $lines;
}

done_testing;
