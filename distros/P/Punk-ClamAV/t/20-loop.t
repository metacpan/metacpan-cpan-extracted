#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk ();
use FakeClamd;

# Scanning on the worker's event loop.
#
# A scan is a socket round trip to a daemon that may have queued the
# request behind a dozen others. Inside an event-driven server, spending
# that in a blocking read stalls every other connection the worker owns -
# which is the entire reason this talks to clamd rather than linking
# libclamav, and it would be silly to give it back here.

BEGIN {
    eval { require Hyperman::Loop; require Hyperman::Future; 1 }
        or plan skip_all => 'Hyperman::Loop not available';
}

my $EICAR = $FakeClamd::EICAR;

our $SRV  = FakeClamd->new(mode => 'sniff');
our $SOCK = $SRV->path;
our $LOOP = Hyperman::Loop->new;
$LOOP->install_await;

diag "loop backend: " . $LOOP->backend;

sub multipart {
    my ($bytes) = @_;
    my $b = '----PunkClamAVLoop';
    return ("--$b\r\n"
          . qq{Content-Disposition: form-data; name="file"; filename="f.bin"\r\n}
          . "Content-Type: application/octet-stream\r\n\r\n"
          . $bytes . "\r\n--$b--\r\n",
            "multipart/form-data; boundary=$b");
}

sub post_upload {
    my ($app, $path, $bytes) = @_;
    my ($body, $type) = multipart($bytes);
    open my $fh, '<', \$body or die $!;
    return $app->({
        REQUEST_METHOD => 'POST', PATH_INFO => $path, QUERY_STRING => '',
        CONTENT_TYPE => $type, CONTENT_LENGTH => length($body),
        'psgi.input' => $fh, 'psgi.errors' => \*STDERR,
    });
}
sub body_of { join '', @{ $_[0][2] || [] } }

{
    package Looped;
    use Punk;
    # `loop` is how a test hands in a standalone loop. In a worker the
    # plugin finds Hyperman->loop by itself and this is not needed.
    plugin 'ClamAV' => { socket => $main::SOCK, loop => $main::LOOP };
    post '/u' => sub {
        my ($c) = @_;
        my $up = $c->upload('file') or return $c->text('no file', 400);
        my $v  = $c->scan_upload($up);
        return $c->text($v->state . '|' . ($v->signature // '-'), 200);
    };
    package main;
    our $APP = Looped->to_app;
}

# --- the verdict is the same as the blocking path -----------------------
{
    my $r = post_upload($main::APP, '/u', $EICAR);
    is body_of($r), 'infected|Eicar-Test-Signature',
        'a scan driven on the loop gives the same verdict as a blocking one';

    $r = post_upload($main::APP, '/u', 'harmless');
    is body_of($r), 'clean|-', '  and a clean upload is still clean';
}

# --- THE POINT: other work runs while the scan is in flight -------------
#
# This needs a peer that actually makes the client wait. A fake on a
# local socket usually has its reply buffered before the first step()
# even looks - so the scan finishes without yielding, which is correct
# behaviour and proves nothing either way. A deliberately slow clamd is
# what creates the wait this phase exists to fill.
{
    my $slow = FakeClamd->new(mode => 'slow', delay => 0.3,
                              literal => 'stream: Eicar-Test-Signature FOUND');
    my $sock = $slow->path;

    {
        package Slow;
        use Punk;
        plugin 'ClamAV' => { socket => $sock, loop => $main::LOOP };
        post '/u' => sub {
            my ($c) = @_;
            my $up = $c->upload('file') or return $c->text('no file', 400);
            return $c->text($c->scan_upload($up)->state, 200);
        };
        package main;
        our $SLOW = Slow->to_app;
    }

    my $ticks = 0;
    my $tick; $tick = sub { $ticks++; $main::LOOP->timer(0.005, $tick) };
    $main::LOOP->timer(0.005, $tick);

    my $t0 = Time::HiRes::time();
    my $r  = post_upload($main::SLOW, '/u', 'payload');
    my $el = Time::HiRes::time() - $t0;

    is body_of($r), 'infected', 'a slow scan still completes correctly';
    cmp_ok $el, '>=', 0.25, '  and really did wait for the peer';
    cmp_ok $ticks, '>', 0,
        'the loop kept running during that wait - other connections progressed';
    diag "  loop ran $ticks times during a ${\ sprintf '%.2f', $el }s scan";
    $slow->stop;
}

# --- a peer that never answers must not park the worker -----------------
# $future->get does not return until the descriptor is ready, and the
# scan's deadline is only checked inside step(). Without a timer racing
# the readiness future, a clamd that accepted and then said nothing would
# hold this worker forever - which is worse than the blocking read this
# replaces.
{
    my $stall = FakeClamd->new(mode => 'stall');
    my $sock  = $stall->path;

    {
        package Stalled;
        use Punk;
        plugin 'ClamAV' => { socket => $sock, loop => $main::LOOP,
                             reply_timeout => 2 };
        post '/u' => sub {
            my ($c) = @_;
            my $up = $c->upload('file') or return $c->text('no file', 400);
            my $v  = $c->scan_upload($up);
            return $c->text($v->state, 200);
        };
        package main;
        our $STALLED = Stalled->to_app;
    }

    my $t0 = Time::HiRes::time();
    my $r  = post_upload($main::STALLED, '/u', 'anything');
    my $el = Time::HiRes::time() - $t0;

    is body_of($r), 'error', 'a peer that never answers ends as an error';
    cmp_ok $el, '>=', 1.5, '  not before the timeout it was given';
    cmp_ok $el, '<',  30,  '  and not never, which is the failure that matters';
    $stall->stop;
}

# --- off-loop it still works --------------------------------------------
# The console, a script, a test without a loop. Same code path, no loop,
# one blocking call - and the caller never had to choose.
{
    package Blocking;
    use Punk;
    plugin 'ClamAV' => { socket => $main::SOCK };   # no loop
    post '/u' => sub {
        my ($c) = @_;
        my $up = $c->upload('file') or return $c->text('no file', 400);
        return $c->text($c->scan_upload($up)->state, 200);
    };
    package main;
    our $BLOCKING = Blocking->to_app;
}
{
    is body_of(post_upload($main::BLOCKING, '/u', $EICAR)), 'infected',
        'with no loop the same helper blocks and still works';
}

BEGIN { require Time::HiRes }

$SRV->stop;
done_testing;
