package PAGI::Test::ConnectionState;
$PAGI::Test::ConnectionState::VERSION = '0.002001';
use strict;
use warnings;

=head1 NAME

PAGI::Test::ConnectionState - the pagi.connection object provided by PAGI::Test

=head1 DESCRIPTION

PAGI::Test is a test server, so it provides the per-request C<pagi.connection>
object. It implements the surface L<PAGI::Request>/L<PAGI::Context> delegate to
(C<is_connected>, C<disconnect_reason>, C<disconnect_future>, C<on_disconnect>,
C<on_complete>) plus C<response_started>, mirroring production
C<PAGI::Server::ConnectionState>: a clean completion ends the request and fires
C<on_complete> but is not a disconnect; exactly one of C<on_complete> /
C<on_disconnect> fires.

=cut

sub new {
    my ($class) = @_;
    return bless {
        _connected        => 1,
        _response_started => 0,
        _completed        => 0,           # explicit terminal-state flag, like production
        _reason           => undef,
        _disc_cbs         => [],
        _comp_cbs         => [],
    }, $class;
}

sub is_connected      { return $_[0]->{_connected} ? 1 : 0 }
sub response_started  { return $_[0]->{_response_started} ? 1 : 0 }
sub disconnect_reason { return $_[0]->{_reason} }
sub disconnect_future { return undef }   # not supported by the test double (spec: undef = unsupported)

# Late registration fires immediately for the terminal state that occurred —
# distinguished by _completed (clean) vs a set _reason (abnormal), like production.
# Invoke a callback the way production does: isolate failures so one bad
# callback does not prevent the others from running.
sub _fire {
    my ($cb, @args) = @_;
    eval { $cb->(@args); 1 } or warn "pagi.connection callback error: $@";
    return;
}

sub on_disconnect {
    my ($self, $cb) = @_;
    if (!$self->{_connected}) {                       # terminal: never store, fire only if abnormal
        _fire($cb, $self->{_reason}) unless $self->{_completed};
        return;
    }
    push @{$self->{_disc_cbs}}, $cb;                   # still in flight: register
    return;
}

sub on_complete {
    my ($self, $cb) = @_;
    if (!$self->{_connected}) {                       # terminal: never store, fire only if clean
        _fire($cb) if $self->{_completed};
        return;
    }
    push @{$self->{_comp_cbs}}, $cb;
    return;
}

# Server-internal (the test client, acting as server, calls these).
sub _mark_response_started { $_[0]->{_response_started} = 1; return }

sub _mark_complete {
    my ($self) = @_;
    return unless $self->{_connected};
    $self->{_connected} = 0;
    $self->{_completed} = 1;                 # clean completion (distinguishes from disconnect)
    _fire($_) for @{$self->{_comp_cbs}};
    @{$self->{_comp_cbs}} = ();
    @{$self->{_disc_cbs}} = ();
    return;
}

sub _mark_disconnected {
    my ($self, $reason) = @_;
    return unless $self->{_connected};
    $self->{_connected} = 0;
    $self->{_reason}    = $reason // 'unknown';   # coerce like production
    _fire($_, $self->{_reason}) for @{$self->{_disc_cbs}};
    @{$self->{_disc_cbs}} = ();
    @{$self->{_comp_cbs}} = ();
    return;
}

1;
