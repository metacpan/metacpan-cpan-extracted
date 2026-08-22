#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk ();
use ClamAV::Clamd ();
use FakeClamd;

# Punk::Plugin::ClamAV: an upload is scanned, and every state that is not
# 'clean' is a rejection - including 'unscannable', which is clamd saying
# it did not look.

my $EICAR = $FakeClamd::EICAR;

# One fake for the whole file. The socket path has to be known before the
# app packages below are compiled, because `plugin` runs at that point.
our $SRV  = FakeClamd->new(mode => "sniff");
our $SOCK = $SRV->path;

sub multipart {
    my (%files) = @_;
    my $b = '----PunkClamAVBoundary';
    my $body = '';
    for my $field (sort keys %files) {
        my ($name, $bytes) = @{ $files{$field} };
        $body .= "--$b\r\n"
               . qq{Content-Disposition: form-data; name="$field"; filename="$name"\r\n}
               . "Content-Type: application/octet-stream\r\n\r\n"
               . $bytes . "\r\n";
    }
    $body .= "--$b--\r\n";
    return ($body, "multipart/form-data; boundary=$b");
}

sub post_upload {
    my ($app, $path, %files) = @_;
    my ($body, $type) = multipart(%files);
    open my $fh, '<', \$body or die $!;
    return $app->({
        REQUEST_METHOD => 'POST',
        PATH_INFO      => $path,
        QUERY_STRING   => '',
        CONTENT_TYPE   => $type,
        CONTENT_LENGTH => length($body),
        'psgi.input'   => $fh,
        'psgi.errors'  => \*STDERR,
    });
}

sub body_of { my ($r) = @_; join '', @{ $r->[2] || [] } }

{
    package Manual;
    use Punk;
    plugin 'ClamAV' => { socket => $main::SOCK };

    post '/upload' => sub {
        my ($c) = @_;
        my $up = $c->upload('file') or return $c->text('no file', 400);
        my $v  = $c->scan_upload($up);
        return $c->text('state=' . $v->state, 422) unless $v->is_clean;
        return $c->text('stored ' . $up->size, 200);
    };

    post '/policy' => sub {
        my ($c) = @_;
        my $up = $c->upload('file') or return $c->text('no file', 400);
        return $c->text('rejected', 422) unless $c->upload_ok($up);
        return $c->text('accepted', 200);
    };

    post '/missing' => sub {
        my ($c) = @_;
        # deliberately asks about a field that was never sent
        return $c->text('rejected', 422) unless $c->upload_ok('nosuchfield');
        return $c->text('accepted', 200);
    };

    post '/all' => sub {
        my ($c) = @_;
        my $all = $c->scan_uploads;
        my @s = map { "$_=" . $all->{$_}[0]->state } sort keys %$all;
        return $c->text(join(',', @s), 200);
    };

    get '/client' => sub {
        my ($c) = @_;
        return $c->text($c->clamd->ping ? 'pong' : 'no');
    };

    package main;
    our $MANUAL = Manual->to_app;
}

# --- the helper scans, and the states come through ----------------------
{
    my $r = post_upload($main::MANUAL, '/upload', file => ['bad.bin', $EICAR]);
    is $r->[0], 422, 'an infected upload is refused by the handler';
    is body_of($r), 'state=infected', '  and the verdict says why';
}

{
    my $r = post_upload($main::MANUAL, '/upload', file => ['ok.txt', 'harmless bytes']);
    is $r->[0], 200, 'a clean upload is accepted';
    like body_of($r), qr/^stored \d+$/, '  and the handler got the upload';
}

# --- upload_ok applies the configured policy ----------------------------
{
    my $r = post_upload($main::MANUAL, '/policy', file => ['bad.bin', $EICAR]);
    is $r->[0], 422, 'upload_ok is false for an infected upload';

    $r = post_upload($main::MANUAL, '/policy', file => ['ok.txt', 'fine']);
    is $r->[0], 200, 'upload_ok is true for a clean one';
}

# --- A NAME THAT MATCHES NOTHING IS NOT A PASS --------------------------
# upload_ok returning true for an upload it never found would make the
# guard a silent no-op - and the classic way for that to happen is a
# handler that fetches one field name and scans another.
{
    my $r = post_upload($main::MANUAL, '/missing', file => ['ok.txt', 'fine']);
    is $r->[0], 422,
        'upload_ok is FALSE for a name that matches no upload';
    is body_of($r), 'rejected', '  nothing scanned is never acceptable';
}

# --- scan_uploads sees every field --------------------------------------
{
    my $r = post_upload($main::MANUAL, '/all',
        a => ['a.txt', 'clean'], b => ['b.bin', $EICAR]);
    is $r->[0], 200, 'scan_uploads runs';
    is body_of($r), 'a=clean,b=infected', '  and reports each field separately';
}

# --- the client is reachable --------------------------------------------
{
    my $r = $main::MANUAL->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/client', QUERY_STRING => '',
        'psgi.input' => undef, 'psgi.errors' => \*STDERR,
    });
    is body_of($r), 'pong', '$c->clamd is the live client';
}

# --- a request with no uploads costs nothing ----------------------------
{
    my $r = $main::MANUAL->({
        REQUEST_METHOD => 'POST', PATH_INFO => '/upload', QUERY_STRING => '',
        CONTENT_TYPE   => 'application/x-www-form-urlencoded',
        CONTENT_LENGTH => 3, 'psgi.input' => do { open my $f, '<', \'a=1' or die; $f },
        'psgi.errors'  => \*STDERR,
    });
    is $r->[0], 400, 'a request with no file part is not scanned, just fileless';
}

# --- UNSCANNABLE IS A REJECTION, NOT A PASS -----------------------------
# The whole reason the verdict has four states. clamd answers OK for
# files it declined to scan; with AlertExceedsMax on it says so, and that
# must not read as clean.
{
    my $srv = FakeClamd->new(mode => 'literal',
        literal => 'stream: Heuristics.Limits.Exceeded.MaxFileSize FOUND');
    my $sock = $srv->path;

    {
        package Unscannable;
        use Punk;
        plugin 'ClamAV' => { socket => $sock };
        post '/u' => sub {
            my ($c) = @_;
            my $up = $c->upload('file') or return $c->text('no file', 400);
            return $c->text('rejected:' . $c->scan_upload($up)->reason, 422)
                unless $c->upload_ok($up);
            return $c->text('accepted', 200);
        };
        package main;
        our $UNSCAN = Unscannable->to_app;
    }

    my $r = post_upload($main::UNSCAN, '/u', file => ['big.bin', 'x' x 100]);
    is $r->[0], 422, 'an upload clamd declined to scan is REJECTED by default';
    is body_of($r), 'rejected:MaxFileSize', '  naming the ceiling that stopped it';
    $srv->stop;
}

# --- on_unscannable => allow is a real choice with a real consequence ---
{
    my $srv = FakeClamd->new(mode => 'literal',
        literal => 'stream: Heuristics.Encrypted.Zip FOUND');
    my $sock = $srv->path;

    {
        package Permissive;
        use Punk;
        plugin 'ClamAV' => { socket => $sock, on_unscannable => 'allow' };
        post '/u' => sub {
            my ($c) = @_;
            my $up = $c->upload('file') or return $c->text('no file', 400);
            return $c->text($c->upload_ok($up) ? 'accepted' : 'rejected',
                            $c->upload_ok($up) ? 200 : 422);
        };
        package main;
        our $PERM = Permissive->to_app;
    }

    my $r = post_upload($main::PERM, '/u', file => ['locked.zip', 'PK']);
    is $r->[0], 200, 'on_unscannable => allow accepts an encrypted archive';
    is body_of($r), 'accepted', '  which is a choice, not a default';
    $srv->stop;
}

# --- FAIL CLOSED --------------------------------------------------------
# A scanner that is down and passes everything IS the vulnerability. This
# is the opposite call from a rate limiter, where failing open is right.
{
    package Dead;
    use Punk;
    plugin 'ClamAV' => { socket => '/tmp/pc-definitely-not-here.sock' };
    post '/u' => sub {
        my ($c) = @_;
        my $up = $c->upload('file') or return $c->text('no file', 400);
        my $v  = $c->scan_upload($up);
        return $c->text('state=' . $v->state, 422) unless $c->upload_ok($up);
        return $c->text('accepted', 200);
    };
    package main;
    our $DEAD = Dead->to_app;
}
{
    my $r = post_upload($main::DEAD, '/u', file => ['x.txt', 'anything']);
    is $r->[0], 422, 'a dead clamd rejects rather than passing everything';
    is body_of($r), 'state=error', '  reported as an error, never as clean';
}

# --- automatic mode -----------------------------------------------------
{
    package Auto;
    use Punk;
    plugin 'ClamAV' => { socket => $main::SOCK, auto => 1 };
    post '/u' => sub { $_[0]->text('handler ran', 200) };
    get  '/g' => sub { $_[0]->text('get ok', 200) };
    package main;
    our $AUTO = Auto->to_app;
}
{
    my $r = post_upload($main::AUTO, '/u', file => ['bad.bin', $EICAR]);
    is $r->[0], 422, 'auto mode answers before the handler runs';
    like body_of($r), qr/infected/, '  saying what was wrong';
    unlike body_of($r), qr/Eicar-Test-Signature/,
        '  and NEVER the signature name, which is attacker-chosen text';

    $r = post_upload($main::AUTO, '/u', file => ['ok.txt', 'fine']);
    is $r->[0], 200, 'a clean upload reaches the handler';
    is body_of($r), 'handler ran', '  which ran normally';

    $r = $main::AUTO->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/g', QUERY_STRING => '',
        'psgi.input' => undef, 'psgi.errors' => \*STDERR,
    });
    is $r->[0], 200, 'a request that cannot carry an upload is not parsed';
}

# --- configuration that cannot work croaks ------------------------------
{
    my $err;
    { local $@; eval { Punk::Plugin::ClamAV->register(bless({}, 'Punk::App'), {}); 1 } or $err = $@ }
    like $err, qr/one of 'socket' or 'host'/, 'no address croaks at plugin time';

    $err = undef;
    { local $@; eval {
        Punk::Plugin::ClamAV->register(bless({}, 'Punk::App'),
            { socket => '/tmp/x.sock', on_error => 'maybe' }); 1 } or $err = $@ }
    like $err, qr/must be 'reject', 'allow' or a coderef/,
        'an unknown policy word croaks rather than silently failing open';
}

# --- THE TRAP THIS PLUGIN FELL INTO ONCE --------------------------------
# ClamAV::Clamd::Verdict overloads bool to is_clean, which is what makes
#     if ($clamd->scan($f)) { accept() }
# correct rather than catastrophic. The same overload makes
#     return 1 unless $v;      # "was there an upload at all?"
# mean "unless it is clean" - so a guard written that way accepts every
# infected upload while reading like a check for a missing one.
#
# Both sites in this plugin use `defined`. This pins the distinction.
{
    my $srv = FakeClamd->new(mode => 'literal',
        literal => 'stream: Eicar-Test-Signature FOUND');
    my $clamd = ClamAV::Clamd->new(socket => $srv->path);
    my $v = $clamd->scan('anything');

    ok defined $v,       'an infected verdict is a defined object';
    ok !$v,              '  but false in boolean context, because bool is is_clean';
    isnt !!$v, !!defined($v),
        'truth and definedness DISAGREE here - which is the whole trap';
    $srv->stop;
}

$SRV->stop;
done_testing;
