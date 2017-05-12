package Protocol::IMAP;
# ABSTRACT: Support for RFC3501 Internet Message Access Protocol (IMAP4)
use strict;
use warnings;
use parent qw(Mixin::Event::Dispatch);

use Encode::IMAPUTF7;
use Scalar::Util qw{weaken};
use Authen::SASL;

use Time::HiRes qw{time};
use POSIX qw{strftime};

our $VERSION = '0.004';

=head1 NAME

Protocol::IMAP - support for the Internet Message Access Protocol as defined in RFC3501.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Protocol::IMAP::Server;
 use Protocol::IMAP::Client;

=head1 DESCRIPTION

Base class for L<Protocol::IMAP::Server> and L<Protocol::IMAP::Client> implementations.

=head1 METHODS

=cut

# Build up an enumerated list of states. These are defined in the RFC and are used to indicate what we expect to send / receive at client and server ends.
our %VALID_STATES;
our %STATE_BY_ID;
our %STATE_BY_NAME;
BEGIN {
	our @STATES = qw{
		ConnectionClosed ConnectionEstablished
		ServerGreeting
		NotAuthenticated Authenticated
		Selected
		Logout
	};
	%VALID_STATES = map { $_ => 1 } @STATES;
	my $state_id = 0;
	foreach (@STATES) {
		my $id = $state_id++;
		$STATE_BY_ID{$id} = $_;
		{ no strict 'refs'; *{__PACKAGE__ . '::' . $_} = sub () { $id } }
	}
	%STATE_BY_NAME = reverse %STATE_BY_ID;

	# Convert from ConnectionClosed to on_connection_closed, etc.
	my @handlers = sort values %STATE_BY_ID;
	@handlers = map {;
		my $v = "on$_";
		$v =~ s/([A-Z])/'_' . lc($1)/ge;
		$v
	} @handlers;
	{ no strict 'refs'; *{__PACKAGE__ . "::STATE_HANDLERS"} = sub () { @handlers } }
}

sub new {
	my $class = shift;
	bless { @_ }, $class
}

=head2 C<debug>

Debug log message. Only displayed if the debug flag was passed to L<configure>.

=cut

sub debug {
	my $self = shift;
	return $self unless $self->{debug};

	my $now = Time::HiRes::time;
	warn strftime("%Y-%m-%d %H:%M:%S", gmtime($now)) . sprintf(".%03d", int($now * 1000.0) % 1000.0) . " @_\n";
	return $self;
}

=head2 C<state>

Sets or retrieves the current state, in text format.

=cut

sub state {
	my $self = shift;
	if(@_) {
		my $name = shift;
		die "Invalid state [$name]" unless defined(my $state_id = $STATE_BY_NAME{$name});
		return $self->state_id($state_id, @_);
	}
	return $STATE_BY_ID{$self->{state_id}};
}

=head2 state_id

Sets or returns the state, in numeric format.

=cut

sub state_id {
	my $self = shift;
	if(@_) {
		my $state_id = shift;
		die "Invalid state ID [$state_id]" unless exists $STATE_BY_ID{$state_id};
		$self->{state_id} = $state_id;
		$self->debug("State changed to " . $state_id . " (" . $STATE_BY_ID{$state_id} . ")");
		$self->invoke_event(state => $STATE_BY_ID{$state_id});
		$self->invoke_event(authenticated => ) if $state_id == $STATE_BY_NAME{Authenticated};
		# ConnectionEstablished => on_connection_established
		my $method = 'on' . $STATE_BY_ID{$state_id};
		$method =~ s/([A-Z])/'_' . lc($1)/ge;
		if($self->{$method}) {
			$self->debug("Trying method for [$method]");
			# If the override returns false, skip the main function
			return $self unless $self->{$method}->(@_);
		}
		$self->$method(@_) if $self->can($method);
		return $self;
	}
	return $self->{state_id};
}

=head2 in_state

Returns true if we're in the given state.

=cut

sub in_state {
	my $self = shift;
	my $expect = shift;
	die "Invalid state $expect" unless exists $VALID_STATES{$expect};
	return +($self->state eq $expect) ? 1 : 0;
}

=head2 C<write>

Raise an error if we call ->write at top level, just in case someone's trying to use this directly.

=cut

sub write {
	my $self = shift;
	$self->invoke_event(write => @_);
}

=head2 C<_capture_weakself>

Helper method to avoid capturing $self in closures, using the same approach and method name
as in L<IO::Async>.

=cut

sub _capture_weakself {
	my ($self, $code) = @_;

	Scalar::Util::weaken($self);

	return sub {
		$self->$code(@_)
	};
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

with thanks to Paul Evans <leonerd@leonerd.co.uk> for the L<IO::Async> framework, which provides
the foundation for L<Net::Async::IMAP>.

=head1 LICENSE

Licensed under the same terms as Perl itself.
