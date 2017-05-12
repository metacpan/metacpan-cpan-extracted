package Net::Async::IMAP::Server;
use strict;
use warnings;
use parent qw{IO::Async::Protocol::Stream Protocol::IMAP::Server};

use Socket;
our $VERSION = '0.003';

=head1 NAME

Net::Async::IMAP::Server - asynchronous IMAP server based on L<Protocol::IMAP::Server> and L<IO::Async::Protocol::Stream>.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::IMAP;
 my $loop = IO::Async::Loop->new;
 my $imap = Net::Async::IMAP::Client->new(
 	loop => $loop,
	host => 'mailserver.com',
	service => 'imap',
	user => 'user@mailserver.com',
	pass => 'password',
	on_authenticated => sub {
		warn "login was successful";
		$loop->loop_stop;
	},
 );
 $loop->loop_forever;

=head1 DESCRIPTION

See L<Protocol::IMAP::Server> for more details on API.

=head1 METHODS

=cut

=head2 C<new>

Instantiate a new object. Will add to the event loop if the C<loop> parameter is passed.

=cut

sub new {
	my $class = shift;
	my %args = @_;

# Clear any options that will cause the parent class to complain
	my $loop = delete $args{loop};

	my $self = $class->SUPER::new( %args );

# Automatically add to the event loop if we were passed one
	$loop->add($self) if $loop;
	return $self;
}

=head2 C<on_read>

Pass any new data into the protocol handler.

=cut

sub on_read {
	my ($self, $buffref, $closed) = @_;
	$self->debug("Had a message");
	$self->debug("Stream was closed, this was not expected") if $closed;

# We'll be called again, don't know where, don't know when, but the rest of our data will be waiting for us
	if($$buffref =~ s/^(.*[\n\r]+)//) {
		my $msg = $1;
		$self->debug("Data received: $msg");
		if($self->is_multi_line) {
			$self->on_multi_line($msg);
		} else {
			$self->on_single_line($msg);
		}
		return 1;
	} else {
		$self->debug("Incomplete data");
	}
	return 0;
}

=head2 C<configure>

Apply callbacks and other parameters, preparing state for event loop start.

=cut

sub configure {
	my $self = shift;
	my %args = @_;

# Debug flag is used to control the copious amounts of data that we dump out when tracing
	$self->{debug} = delete $args{debug} ? 1 : 0;

# Don't think I like this much, but didn't want the list of callbacks held here
	%args = $self->Protocol::IMAP::Server::configure(%args);

	$self->SUPER::configure(%args);
	return $self;
}

sub on_user {
	my $self = shift;
	return $self->{user};
}

sub on_pass {
	my $self = shift;
	return $self->{pass};
}

=head2 C<start_idle_timer>

=cut

sub start_idle_timer {
	my $self = shift;
	my %args = @_;

	$self->{idle_timer}->stop if $self->{idle_timer};
	$self->{idle_timer} = IO::Async::Timer::Countdown->new(
		delay => $args{idle_timeout} || 25 * 60,
		on_expire => $self->_capture_weakself( sub {
			my $self = shift;
			$self->done(
				on_ok => sub {
					$self->noop(
						on_ok => sub {
							$self->idle(%args);
						}
					);
				}
			);
		})
	);
	my $loop = $self->get_loop or die "Could not get loop";
	$loop->add($self->{idle_timer});
	$self->{idle_timer}->start;
	return $self;
}

=head2 C<stop_idle_timer>

Disable the timer if it's running.

=cut

sub stop_idle_timer {
	my $self = shift;
	$self->{idle_timer}->stop if $self->{idle_timer};
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <net-async-imap@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2011. Licensed under the same terms as Perl itself.
