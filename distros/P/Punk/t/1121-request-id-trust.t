#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();
use Punk ();

# Adopting an id handed in by a proxy.
#
# An inbound id is REQUEST BYTES, and this workspace has been bitten by that
# class three times (CVE-2026-75628, the Punk markdown 301, the
# Reverse::Proxy smuggling fix). It reaches two dangerous places: a log line
# and a response header. A CR in the first forges a log entry; a CR in the
# second splits the response.

sub env_for {
    my (%extra) = @_;
    return {
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/',
        QUERY_STRING   => '',
        'psgi.input'   => undef,
        'psgi.errors'  => \*STDERR,
        %extra,
    };
}

{
    package Untrusting;
    use Punk;
    plugin 'RequestId';
    get '/' => sub { $_[0]->text($_[0]->request_id) };

    package Trusting;
    use Punk;
    plugin 'RequestId' => { trust_header => 1 };
    get '/' => sub { $_[0]->text($_[0]->request_id) };

    package main;
    our $UNTRUSTING = Untrusting->to_app;
    our $TRUSTING   = Trusting->to_app;
}

# ---- off by default ----------------------------------------------------------
# Punk sits behind a proxy in production and on localhost in development, and
# in the second case X-Request-Id is whatever the client felt like sending.
{
    my $res = $main::UNTRUSTING->(env_for(HTTP_X_REQUEST_ID => 'client-chose-this'));
    my $id  = $res->[2][0];
    isnt($id, 'client-chose-this',
        'by DEFAULT an inbound id is ignored - a default that trusted it '
      . 'would write attacker-chosen bytes into the log of every application '
      . 'that copied the synopsis');
    like($id, qr/\A[0-9a-f]{32}\z/, 'and a fresh one is issued instead');
}

# ---- adopted when asked for --------------------------------------------------
{
    my $res = $main::TRUSTING->(env_for(HTTP_X_REQUEST_ID => 'abc123'));
    is($res->[2][0], 'abc123', 'trust_header adopts a well-formed inbound id');

    my %h = @{ $res->[1] };
    is($h{'X-Request-Id'}, 'abc123',
        'and echoes it back, which is the whole point - one id spanning the '
      . 'chain rather than one per hop');
}

# ---- rejected, not sanitised -------------------------------------------------
# A value that fails is REPLACED. Trimming it into shape would produce a third
# value that correlates with nothing at either end.
{
    my @bad = (
        [ 'a CR and LF'        => "bad\r\nX-Evil: 1" ],
        [ 'a bare LF'          => "bad\nX-Evil: 1"   ],
        [ 'a bare CR'          => "bad\rX-Evil: 1"   ],
        [ 'a NUL'              => "bad\0id"          ],
        [ 'a tab'              => "bad\tid"          ],
        [ 'a space'            => 'bad id'           ],
        [ 'a DEL'              => "bad\x7fid"        ],
        [ 'a high byte'        => "bad\xffid"        ],
        [ 'an empty value'     => ''                 ],
        [ '129 bytes'          => 'x' x 129          ],
        [ 'a kilobyte'         => 'x' x 1024         ],
    );

    for my $b (@bad) {
        my ($what, $value) = @$b;
        my $res = $main::TRUSTING->(env_for(HTTP_X_REQUEST_ID => $value));
        my $id  = $res->[2][0];
        like($id, qr/\A[0-9a-f]{32}\z/,
            "$what is refused and a fresh id issued, not trimmed into shape");
    }

    # 128 is the boundary, and the boundary should be usable
    my $ok = 'y' x 128;
    is($main::TRUSTING->(env_for(HTTP_X_REQUEST_ID => $ok))->[2][0], $ok,
        '128 bytes is accepted - the cap is a cap, not an off-by-one');
}

# ---- the refusals are counted ------------------------------------------------
{
    my %before = Punk::Plugin::RequestId->stats;
    $main::TRUSTING->(env_for(HTTP_X_REQUEST_ID => "nope\r\n"));
    $main::TRUSTING->(env_for(HTTP_X_REQUEST_ID => 'fine-one'));
    my %after = Punk::Plugin::RequestId->stats;

    is($after{rejected}, $before{rejected} + 1, 'a refusal is counted');
    is($after{adopted},  $before{adopted}  + 1, 'and so is an adoption');
    cmp_ok($after{minted}, '>', $before{minted},
        'a refusal mints a replacement, which is counted as a mint - a '
      . 'rising rejected count is somebody probing, and an operator should '
      . 'be able to see it rather than have it discarded silently');
}

# ---- trust needs something to read -------------------------------------------
{
    my $err = do {
        local $@;
        eval {
            package Contradiction;
            use Punk;
            plugin 'RequestId' => { trust_header => 1, header => 0 };
            get '/' => sub { };
            1;
        };
        $@;
    };
    like($err, qr/trust_header needs a header to read/,
        'trust_header with header => 0 croaks at boot rather than silently '
      . 'trusting nothing');
}

# ---- THE GATE: the raw bytes on the wire -------------------------------------
# Asserted on the bytes a client actually receives, not on a parsed structure.
# A parser normalises away exactly the injection being tested for, so a test
# that reads $res->[1] as a hash would pass whether or not the response was
# split.
SKIP: {
    skip 'fork is POSIX-only here', 4 if $^O eq 'MSWin32';
    skip 'Hyperman required to serve real bytes', 4
        unless eval { require Hyperman; 1 };

    my $port = 27400 + ($$ % 150);
    my $host = "127.0.0.1:$port";

    my $pid = fork // die "fork: $!";
    if (!$pid) {
        open STDERR, '>', '/dev/null';

        package WireApp;
        use Punk;
        plugin 'RequestId' => { trust_header => 1 };
        get '/' => sub { $_[0]->text('ok') };

        package main;
        Hyperman->run(app => WireApp->to_app, host => '127.0.0.1',
                      port => $port, workers => 1);
        exit 0;
    }

    for (1 .. 80) {
        my $s = IO::Socket::INET->new(PeerAddr => $host);
        last if $s;
        Time::HiRes::sleep(0.1);
    }

    # Raw, because the point is what arrives byte for byte.
    my $raw = sub {
        my ($request) = @_;
        my $s = IO::Socket::INET->new(PeerAddr => $host) or return '';
        $s->autoflush(1);
        syswrite $s, $request;
        my $buf = '';
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 5;
            while (sysread $s, my $chunk, 4096) { $buf .= $chunk }
            alarm 0;
        };
        alarm 0;
        close $s;
        return $buf;
    };

    my $clean = $raw->("GET / HTTP/1.1\r\nHost: $host\r\n"
                     . "X-Request-Id: proxy-gave-this\r\n"
                     . "Connection: close\r\n\r\n");
    like($clean, qr/^X-Request-Id: proxy-gave-this\r$/m,
        'a well-formed inbound id comes back on the wire verbatim');

    # The obs-fold vector: a header continued on the next line. Whatever the
    # server hands the application, the value must not reach the response
    # carrying a CR, an LF or a tab.
    my $folded = $raw->("GET / HTTP/1.1\r\nHost: $host\r\n"
                      . "X-Request-Id: folded\r\n\tcontinued\r\n"
                      . "Connection: close\r\n\r\n");

    # And the direct attempt: a second header smuggled after the id.
    my $split = $raw->("GET / HTTP/1.1\r\nHost: $host\r\n"
                     . "X-Request-Id: bad\r\nX-Injected: yes\r\n"
                     . "Connection: close\r\n\r\n");

    for my $case ([ 'folded' => $folded ], [ 'split' => $split ]) {
        my ($what, $bytes) = @$case;
        my ($head) = split /\r\n\r\n/, $bytes, 2;
        my @idlines = grep { /^X-Request-Id:/i } split /\r\n/, $head;
        is(scalar @idlines, 1,
            "the $what attempt yields exactly ONE X-Request-Id line - not a "
          . 'second header conjured out of the value');
    }

    kill 'TERM', $pid;
    waitpid $pid, 0;
}

done_testing;
