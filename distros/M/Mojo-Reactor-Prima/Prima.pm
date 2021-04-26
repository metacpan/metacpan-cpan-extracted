package Mojo::Reactor::Prima;

use strict;
use warnings;
use Carp 'croak';
use Prima qw(Utils);
use Mojo::Base 'Mojo::Reactor';
use Mojo::Util qw(md5_sum steady_time);
use Scalar::Util qw(weaken);
our $VERSION = '1.01';

$ENV{MOJO_REACTOR} ||= 'Mojo::Reactor::Prima';

my ($refcnt, $destroy, %loops, $current);

sub new
{
	my $self = shift->SUPER::new;
	$refcnt++;
	unless ( $::application ) {
		$::application = Prima::Application->new;
		$destroy = 1;
	}
	$self->{timers} = {};
	$self->{io}     = {};
	$loops{"$self"} = $self;
	weaken $loops{"$self"};
	$current //= "$self";
	return $self;
}

sub DESTROY
{
	my $self = shift;
	delete $loops{"$self"};
	if (0 == --$refcnt && $destroy && $::application) {
		$::application->destroy if $::application->alive;
		$::application = undef;
	}
}

sub again
{
	my $self = shift;
	croak 'Timer not active' unless my $timer = $self->{timers}{shift()};
	$timer->{watcher}->stop;
	$timer->{watcher}->start if $self->_is_active;
}

sub io
{
	my ($self, $handle, $cb) = @_;
	$self->{io}{fileno($handle) // croak 'Handle is closed'} = {cb => $cb};
	return $self->watch($handle, 1, 1);
}

sub is_running { !!shift->{running} }

sub _next
{
	my $self = shift;
	delete $self->{next_timer};
	while (my $cb = shift @{$self->{next_tick}}) { $self->$cb() }
}

sub next_tick
{
	my ($self, $cb) = @_;
	push @{$self->{next_tick}}, $cb;
	$self->{next_timer} //= $self->timer(0 => \&_next);
	return undef;
}

sub one_tick
{
	my $self = shift;
	return $self->stop unless keys %{ $self->{io} } || keys %{ $self->{timers} };
	local $self->{running} = 1 unless $self->{running};
	$self-> _select;
	$::application->yield(1);
}

sub recurring { shift->_timer(1, @_) }

sub remove
{
	my ($self, $remove) = @_;
	my $obj;
	return 0 unless defined $remove;
	if ( ref($remove)) {
		$obj = delete $self->{io}{fileno($remove) // croak 'Handle is closed'};
	} else {
		$obj = delete $self->{timers}{$remove};
	}
	$obj->{watcher}->destroy if $obj && $obj->{watcher};
	return !!$obj;
}

sub reset
{
	my $self = shift;
	$_->destroy for grep { defined } map { $_->{watcher} }
		values (%{ $self->{io} }),
		values (%{ $self->{timers} });
	;
	delete @{$self}{qw(io next_tick next_timer timers events)}
}

sub start
{
	my $self = shift;
	return unless keys %{ $self->{io} } || keys %{ $self->{timers} };
	local $self->{running} = ($self->{running} || 0) + 1;
	$self-> _select;
	$::application->go;
}

sub stop
{
	delete shift->{running};
	$::application->stop;
}

sub timer { shift->_timer(0, @_) }

sub _watch_read_cb
{
	my ($self, $obj, $fd) = @_;
	$self->_try('I/O watcher', $self->{io}{$fd}{cb}, 0);
}

sub _watch_write_cb
{
	my ($self, $obj, $fd) = @_;
	$self->_try('I/O watcher', $self->{io}{$fd}{cb}, 1);
}

sub watch
{
	my ($self, $handle, $read, $write) = @_;

	my $fd = fileno $handle;
	croak 'I/O watcher not active' unless my $io = $self->{io}{$fd};

	my $mode = 0;
	$mode |= fe::Read  if $read;
	$mode |= fe::Write if $write;

	my $obj = $io->{watcher} //= Prima::File->new(
		fd      => $fd,
		onRead  => sub { $self->_try('I/O watcher', $self->{io}{$fd}{cb}, 0) },
		onWrite => sub { $self->_try('I/O watcher', $self->{io}{$fd}{cb}, 1) },
	);
	$io->{mask} = $mode;
	$obj->mask($mode) if $self->_is_active;

	return $self;
}

sub _id
{
	my $self = shift;
	my $id;
	do { $id = md5_sum 't' . steady_time . rand } while $self->{timers}{$id};
	return $id;
}

sub _timer
{
	my ($self, $recurring, $after, $cb) = @_;
	$after ||= 0.0001;
	my $id  = $self->_id;

	my $t = $self->{timers}{$id}{watcher} = Prima::Timer->new(
		timeout => $after * 1000,
		onTick  => sub {
			unless ($recurring) {
				$_[0]->destroy;
	  			delete $self->{timers}{$id};
			}
	  		$self->_try('Timer', $cb);
		},
	);
	$t->start if $self->_is_active;
	return $id;
}

sub _try
{
	my ($self, $what, $cb) = @_;
	eval { $self->$cb($self, @_); 1 } or $self->emit(error => "$what failed: $@");
	$self->stop unless keys %{ $self->{io} } || keys %{ $self->{timers} };
}

sub _is_active { $_[0] eq $current || $_[0]->{running } }

sub _select
{
	my $self = shift;
	return if $current eq "$self";
	$current = "$self";
	for my $loop ( values %loops ) {
		if ( $self eq $loop ) {
			$_->{watcher}->start for values %{ $loop->{timers} };
			$_->{watcher}->mask( $_->{mask} ) for values %{ $loop->{io} };
		} elsif ( ! $loop->{running} ) {
			$_->{watcher}->stop for values %{ $loop->{timers} };
			$_->{watcher}->mask( 0 ) for values %{ $loop->{io} };
		}
	}
}

1;

=pod

=head1 NAME

Mojo::Reactor::Prima - Prima event loop backend for Mojo::Reactor

=head1 DESCRIPTION

L<Mojo::Reactor::Prima> is an event reactor for L<Mojo::IOLoop> that uses
L<Prima>. The usage is exactly the same as other L<Mojo::Reactor>
implementations such as L<Mojo::Reactor::Poll>. L<Mojo::Reactor::Prima> will be
used as the default backend for L<Mojo::IOLoop> if it is loaded before
L<Mojo::IOLoop> or any module using the loop. However, when invoking a
L<Mojolicious> application through L<morbo> or L<hypnotoad>, the reactor must
be set as the default by setting the C<MOJO_REACTOR> environment variable to
C<Mojo::Reactor::Prima>.

=head1 AUTHOR

Dmitry Karasik E<lt>dmitry@karasik.eu.orgE<gt>

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::IOLoop>, L<Prima>

=cut
