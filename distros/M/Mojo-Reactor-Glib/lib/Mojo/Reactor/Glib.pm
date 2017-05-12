package Mojo::Reactor::Glib;
use Mojo::Base 'Mojo::Reactor';

use strict;
use warnings;

use Glib;

=head1 NAME

Mojo::Reactor::Glib - Glib::MainLoop backend for Mojo

=head1 VERSION

Version 0.002

I hope I need not to emphasise that this is in VERY EARLY STAGES OF DEVELOPMENT.

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

B<Mojo::Reactor::Glib> is a backend for L<Mojo::Reactor>, build on top of the L<Glib> main loop,
allowing you to use various Mojo(licious) modules within a Glib or Gtk program.

    BEGIN {
        $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Glib';
    }

    use Gtk2 -init;
    use Mojo::UserAgent;

    my $ua = Mojo::UserAgent->new();

    Glib::Timeout->add(1000, sub {
        $ua->get('http://example.com/' => sub {
            my ($ua, $tx) = @_;
            say $tx->res->body;
        });
        return Glib::SOURCE_CONTINUE;
    });

    Gtk2->main();

=cut

my $Glib;
$ENV{MOJO_REACTOR} ||= 'Mojo::Reactor::Glib';

sub CLONE {
	die "We don't work with ithreads.\n"; ## To be honest, I don't know, don't care, don't want.
}

sub DESTROY {
	undef $Glib;
}

=head1 METHODS

=head2 Mojo::Reactor::Glib->new()
X<new>

Just the constructor.  You probably won't ever call it yourself.

=cut
sub new {
	my $class = shift;

	if ($Glib) {
		return $Glib;
	} else {
		my $r = {
			loop => undef,
			timers => {},
			io => {},
		};
		bless($r, $class);
		$Glib = $r;
		return $r;
	}
}

#####

=head2 $r->again($id)
X<again>

Runs the timer known by C<$id> again

=cut
sub again {
	my $r = shift;
	my ($id) = @_;

	if (my $s = $r->{timers}->{$id}) {
		$r->_timer($s->{recurring}, $s->{after_sec}, $s->{cb});
	}
}

=head2 $r->io($handle, $cb)
X<io>

Assigns a callback function C<$cb> to the IO handle C<$handle>.  This is required before you can use L<watch|/r-watch-handle-read-write>.

Returns the reactor C<$r> so you can chain the calls.

=cut
sub io {
	my $r = shift;
	my ($handle, $cb) = @_;

	my $fd = fileno($handle);
	$r->{io}->{$fd} //= {};
	$r->{io}->{$fd}->{handle} = $handle;
	$r->{io}->{$fd}->{cb} = $cb;

	return $r;
}

=head2 $r->is_running()
X<is_running>

Returns true if the loop is running, otherwise returns false

=cut
sub is_running {
	my $r = shift;
	return ($r->{loop} ? $r->{loop}->is_running() : 0);
}

=head2 $r->one_tick()
X<one_tick>

Does a single L<Glib::MainLoop> iteration.  Returns true if events were dispatched during this iteration
(whether or not they had been B<Mojo::Reactor::Glib> events), false if nothing happened.

=cut
sub one_tick {
	my $r = shift;

	if ($r->{loop}) {
		my $ctx = $r->{loop}->get_context();
		$ctx && $ctx->iteration(Glib::FALSE);
	}
}

=head2 $r->recurring($after_sec, $cb)
X<recurring>

Starts a recurring timer that beats every C<$after_sec> seconds (N.B. Glib allows for millisecond granularity),
which will result in C<$cb> being fired.

Returns the B<Glib::Timeout> ID that you can use to L<stop|/r-stop> the timer.

See also L<timer|/r-timer-after_sec-cb>

=cut
sub recurring {
	my $r = shift;

	$r->_timer(Glib::SOURCE_CONTINUE, @_);
}

=head2 $r->remove($id)
X<remove>

Removes the timer identified by C<$id>, returning true if this was successful, and a false-ish value otherwise.

=cut
sub remove {
	my $r = shift;
	my ($id) = @_;

	my $removed;
	if (exists $r->{timers}->{$id}) {
		$removed = Glib::Source->remove($id);
		delete $r->{timers}->{$id};
	}

	return $removed;
}

=head2 $r->reset()
X<reset>

Stops all timers and watches.

=cut
sub reset {
	my $r = shift;

	for my $id (keys %{$r->{timers}}) {
		Glib::Source->remove($id);
		delete $r->{timers}->{$id};
	}
	for my $fd (keys %{$r->{io}}) {
		my $handle = $r->{io}->{$fd}->{handle};
		$r->watch($handle, 0, 0);
	}
}

=head2 $r->start()
X<start>

Starts the loop if it isn't already running.

=cut
sub start {
	my $r = shift;

	if (not $r->{loop}) {
		$r->{loop} = Glib::MainLoop->new(undef, Glib::FALSE);
	}

	if ($r->{loop} and not $r->{loop}->is_running()) {
		$r->{loop}->run();
	}
}

=head2 $r->stop()
X<stop>

Stops the loop.

=cut
sub stop {
	my $r = shift;

	if ($r->{loop}) {
		$r->{loop}->quit();
	}
}

=head2 $r->timer($after_sec, $cb)
X<timer>

Starts a one-shot timer that beats after C<$after_sec> seconds (N.B. Glib allows for millisecond granularity),
which will result in C<$cb> being fired.

Returns the B<Glib::Timeout> ID that you can use to L<stop|/r-stop> or L<again|/r-again-id> the timer.

See also L<recurring|/r-recurring-after_sec-cb>.

=cut
sub timer {
	my $r = shift;

	$r->_timer(Glib::SOURCE_REMOVE, @_);
}

=head2 $r->watch($handle, $read, $write)
X<watch>

Adds an IO watch for C<$read> or C<$write> (booleans) on C<$handle>.  If both C<$read>
and C<$write> are false, it removes the watch.

Requires L<io|/r-io-handle-cb> to be run on C<$handle> first, as that associates the callback function with the handle.

See also L<io|/r-io-handle-cb>.

=cut
sub watch {
	my $r = shift;
	my ($handle, $read, $write) = @_;

	my $fd = fileno($handle);
	my $io = $r->{io}->{$fd};

	if (not defined $io) {
		return; ## Croak?
	}

	if ($io->{id}) {
		Glib::Source->remove($io->{id});
	}

	if ($read or $write) {
		my $watchlist = [
			'hup', 'err',
			($read ? 'in' : ()),
			($write ? 'out' : ()),
		];
		my $id = Glib::IO->add_watch($fd, $watchlist, sub {
			my ($fd, $iocondition) = @_;
			$io->{cb}->($r, $iocondition eq 'out' ? 1 : 0);

			return Glib::SOURCE_CONTINUE;
		});
		$io->{id} = $id;
	}

	return $r;
}


sub _timer {
	my $r = shift;
	my ($recurring, $after_sec, $cb) = @_;

	$after_sec = 0 if $after_sec < 0;
	my $after_ms = int($after_sec * 1000);

	my $id = Glib::Timeout->add($after_ms, sub {
		$cb->();
		return $recurring;
	});

	$r->{timers}->{$id} = {
		recurring => $recurring,
		after_sec => $after_sec,
		cb => $cb,
	};

	return $id;
}

=head1 AUTHOR

Ralesk C<< <ralesk at cpan.org> >>

=head1 BUGS

Please report issues at L<https://bitbucket.org/ralesk/mojo-reactor-glib/issues>

=head2 KNOWN ISSUES

=over

=item *

Breaks on Win32, Mojo::UserAgent can't do non-blocking calls at least.

=item *

Can't latch onto an existing Gtk event loop (no API for that), not sure if we actually should be able to or if we're good here in a sub-loop.

=back

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2014 Henrik Pauli

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License (2.0). You may obtain a
copy of the full licence at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of Mojo::Reactor::Glib
