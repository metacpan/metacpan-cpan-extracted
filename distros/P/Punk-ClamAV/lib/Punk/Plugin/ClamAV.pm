package Punk::Plugin::ClamAV;

use 5.010;
use strict;
use warnings;
use parent 'Punk::Plugin';
use Carp ();
use ClamAV::Clamd ();
use Hyperman;
use Hyperman::Future;

our $VERSION = '0.01';

our %WORDS;

BEGIN {
    %WORDS = map { $_ => 1 } qw(reject allow);
}

sub register {
    my ($self, $app, $opts) = @_;
    $opts ||= {};

    my %client = map { exists $opts->{$_} ? ($_ => $opts->{$_}) : () }
        qw(socket host port connect_timeout reply_timeout reply_max
           chunk max_size frame);

    Carp::croak("Punk::Plugin::ClamAV: one of 'socket' or 'host' is required")
        unless defined $client{socket} || defined $client{host};

    my $clamd = ClamAV::Clamd->new(%client);

    my %policy = (
        infected    => _policy($opts->{on_infected},    'reject', 'on_infected'),
        unscannable => _policy($opts->{on_unscannable}, 'reject', 'on_unscannable'),
        error       => _policy($opts->{on_error},       'reject', 'on_error'),
    );
    my $status   = $opts->{status} || 422;
    my $loop_opt = $opts->{loop};
    my $backstop = $opts->{reply_timeout} || 30;

    $app->helper(clamd => sub { $clamd });

    $app->helper(scan_upload => sub {
        my ($c, $up) = @_;
        $up = $c->upload($up) unless ref $up;
        return undef unless $up;
        my $loop = _loop($loop_opt);
        my $path = $up->path;
        return (defined $path && length $path)
            ? _drive($clamd, $loop, 'path',  $path,          $backstop)
            : _drive($clamd, $loop, 'bytes', $up->content,   $backstop);
    });

    $app->helper(scan_uploads => sub {
        my ($c) = @_;
        my $ups = $c->req->uploads or return {};
        my %out;
        for my $name (keys %$ups) {
            my $v = $ups->{$name};
            $out{$name} = [ map { $c->scan_upload($_) }
                            (ref $v eq 'ARRAY' ? @$v : $v) ];
        }
        return \%out;
    });

    $app->helper(upload_ok => sub {
        my ($c, $up) = @_;
        my $v = $c->scan_upload($up);
        return 0 unless defined $v;
        return 1 if $v->is_clean;
        my $act = $policy{ $v->state } // 'reject';
        return ref $act eq 'CODE' ? 0 : ($act eq 'allow' ? 1 : 0);
    });

    if ($opts->{auto}) {
        $app->hook(before_dispatch => sub {
            my ($c) = @_;

            my $ct = $c->req->header('Content-Type') // '';
            return unless $ct =~ m{^\s*multipart/form-data}i;

            my $ups = $c->req->uploads or return;

            for my $name (sort keys %$ups) {
                my $v = $ups->{$name};
                for my $up (ref $v eq 'ARRAY' ? @$v : $v) {
                    my $verdict = $c->scan_upload($up);

                    next if !defined $verdict || $verdict->is_clean;

                    my $act = $policy{ $verdict->state } // 'reject';
                    next if !ref($act) && $act eq 'allow';

                    return $act->($c, $verdict, $up) if ref $act eq 'CODE';
                    return $c->text(_why($verdict), $status);
                }
            }
            return;
        });
    }

    return;
}

sub _loop {
    my ($explicit) = @_;
    return $explicit if $explicit;
    my $l = eval { Hyperman->loop };
    return $l;
}

sub _drive {
    my ($clamd, $loop, $kind, $what, $backstop) = @_;

    unless ($loop) {
        return $kind eq 'path' ? $clamd->scan_path($what)
             : $kind eq 'fd'   ? $clamd->scan_fd($what)
             :                   $clamd->scan($what);
    }

    my $scan = $clamd->start_scan($what, $kind);

    until ($scan->step) {
        my $fd   = $scan->fd;
        my $want = $scan->want;
        last unless defined $fd && defined $want;

        open my $fh, '+<&', $fd or last;

        my $io = $want eq 'read' ? $loop->readable_f($fh)
                                 : $loop->writable_f($fh);
        my $to = $loop->timer_f($backstop);

        my $ok = eval { Hyperman::Future->wait_any($io, $to)->get; 1 };

        for my $f ($io, $to) { eval { $f->cancel unless $f->is_ready } }
        close $fh;
        last unless $ok;
    }
    return $scan->verdict;
}

sub _policy {
    my ($given, $default, $what) = @_;
    return $default unless defined $given;
    return $given if ref $given eq 'CODE';
    Carp::croak("Punk::Plugin::ClamAV: $what must be 'reject', 'allow' "
              . "or a coderef, not '$given'")
        unless $WORDS{$given};
    return $given;
}

sub _why {
    my ($v) = @_;
    return 'upload rejected: infected'                      if $v->is_infected;
    return 'upload rejected: could not be scanned'          if $v->is_unscannable;
    return 'upload rejected: virus scanner unavailable';
}

1;

__END__

=head1 NAME

Punk::Plugin::ClamAV - scan Punk uploads with clamd

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    plugin 'ClamAV' => { socket => '/run/clamav/clamd.ctl' };

    # upload_ok: the short form, applying the policy configured above
    post '/avatar' => sub {
        my ($c) = @_;
        my $up = $c->upload('file') or return $c->text('no file', 400);

        return $c->text('no thanks', 422) unless $c->upload_ok($up);

        # NOT $up->filename - that is request bytes, not a path
        $up->save('/var/lib/app/avatars/' . $c->auth_id);
        $c->json({ ok => 1 });
    };

    # scan_upload: the verdict itself, when "no" is not a good enough answer
    post '/document' => sub {
        my ($c) = @_;
        my $up = $c->upload('file') or return $c->text('no file', 400);
        my $v  = $c->scan_upload($up);

        unless ($v->is_clean) {
            $c->log->warn('rejected upload: ' . $v->state
                        . ($v->signature ? ' (' . $v->signature . ')' : ''));

            return $c->text('that file cannot be accepted', 422) if $v->is_infected;
            return $c->text('we could not scan that - if it is a '
                          . 'password-protected archive, send it unlocked', 422)
                if $v->is_unscannable;
            return $c->text('try again shortly', 503);      # scanner unavailable
        }

        $up->save('/var/lib/app/docs/' . $c->auth_id);
        $c->json({ ok => 1 });
    };

=head1 DESCRIPTION

L<Punk::Upload> streams anything over 64 KiB to a private temp file, so an
upload arrives as attacker-controlled bytes already on your filesystem.
This scans them, through L<ClamAV::Clamd>.

=head2 It picks the cheap transport for you

A spilled upload is already a file, so it is scanned B<by descriptor>:
clamd is handed the open file, not a path, and therefore needs no
permission on your spool directory at all. A small upload never touched
disk and is sent as bytes rather than being written out just so it can be
scanned.

=head1 OPTIONS

    plugin 'ClamAV' => {
        socket         => '/run/clamav/clamd.ctl',   # or host/port
        max_size       => 100 * 1024 * 1024,
        on_infected    => 'reject',
        on_unscannable => 'reject',
        on_error       => 'reject',
        status         => 422,
        auto           => 0,
    };

C<socket>, or C<host> and C<port>, plus C<connect_timeout>,
C<reply_timeout>, C<reply_max>, C<chunk>, C<max_size> and C<frame> are
passed to L<ClamAV::Clamd/new>.

C<loop> takes an event loop to drive scans on, for the unusual case of
wanting one that is not the worker's. Leave it alone and the plugin finds
C<< Hyperman->loop >> per request, which is the right answer inside a
worker and undef everywhere else.

C<on_infected>, C<on_unscannable> and C<on_error> take C<'reject'>,
C<'allow'>, or a coderef called as C<< $cb->($c, $verdict, $upload) >>
whose return value becomes the response.

=head2 All three default to reject

This is the opposite call from a rate limiter, where failing open is
correct because a broken limiter should not take the site down. A scanner
that is down and lets everything through B<is> the vulnerability.

C<on_unscannable> defaulting to reject is the one worth thinking about,
because it is the one that will reject uploads your users consider
perfectly good - a password-protected zip, most obviously. Setting it to
C<'allow'> is a real choice with a real consequence: it accepts files
nothing has looked inside.

=head1 HELPERS

=head2 $c->scan_upload($upload_or_name)

Returns a C<ClamAV::Clamd::Verdict>, or undef if there is no such upload.

=head2 $c->scan_uploads

Scan every upload on the request.

=head2 $c->upload_ok($upload_or_name)

True if the configured policy accepts it.

=head2 $c->clamd

The L<ClamAV::Clamd> client, for anything this plugin does not cover.

=head1 AUTOMATIC MODE, AND WHY IT IS OFF

    plugin 'ClamAV' => { socket => '...', auto => 1 };

Scans every upload on every C<multipart/form-data> request and answers
C<422> rather than dispatching. Requests that cannot carry an upload are
not parsed, so routes without files pay nothing.

B<It runs before your route's guards.> Punk's C<before_dispatch> phase is
ahead of the guards an C<under> scope puts on a route, and there is currently no
public phase between them. So with C<auto> on, an B<unauthenticated>
caller can make your server accept, spool and scan a 128 MiB file that
your authentication guard was about to refuse.

=head1 WHAT THE CLIENT IS TOLD

A rejection says C<infected>, C<could not be scanned>, or C<virus scanner
unavailable>, and B<never the signature name>. A signature name is chosen,
in effect, by whoever supplied the file: a file crafted to match a given
signature decides what string comes back. Log it; do not reflect it.

=head2 It does not block the worker

On a Hyperman worker the scan is driven on that worker's event loop. The
descriptor is watched, the scan is stepped on readiness, and the wait
happens inside a future whose C<get> pumps the loop. The worker keeps
serving every other connection it owns for the length of the scan.

=head1 SEE ALSO

L<ClamAV::Clamd>, L<Punk>, L<Punk::Upload>, L<Punk::Plugin>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
