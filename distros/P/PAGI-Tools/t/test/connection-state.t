use strict; use warnings; use Test::More;
use PAGI::Test::ConnectionState;

my $conn = PAGI::Test::ConnectionState->new;
is $conn->is_connected,     1, 'connected initially';
is $conn->response_started, 0, 'not started';
is $conn->disconnect_reason, undef, 'no reason';

$conn->_mark_response_started;
is $conn->response_started, 1, 'started after mark';

my @fired;
$conn->on_complete(sub { push @fired, 'complete' });
$conn->on_disconnect(sub { push @fired, 'disconnect' });
$conn->_mark_complete;
is_deeply \@fired, ['complete'], 'on_complete fires, on_disconnect does not';
is $conn->is_connected,      0, 'completion ends the request (matches production)';
is $conn->disconnect_reason, undef, 'clean completion is not a disconnect';

# on_complete registered after completion fires immediately:
my $late; $conn->on_complete(sub { $late = 1 });
is $late, 1, 'late on_complete fires immediately';
# on_disconnect registered after a clean completion is dropped (never fires, not stored):
my $never; $conn->on_disconnect(sub { $never = 1 });
is $never, undef, 'on_disconnect after clean completion does not fire';

# Abnormal disconnect: fires on_disconnect (with reason), not on_complete.
my $d = PAGI::Test::ConnectionState->new;
my @df;
$d->on_complete(sub { push @df, 'complete' });
$d->on_disconnect(sub { push @df, "disc:$_[0]" });
$d->_mark_disconnected('client_closed');
is_deeply \@df, ['disc:client_closed'], 'on_disconnect fires with reason; on_complete does not';
is $d->disconnect_reason, 'client_closed', 'reason recorded';
my $latecomplete; $d->on_complete(sub { $latecomplete = 1 });
is $latecomplete, undef, 'on_complete after abnormal disconnect is dropped';
is $d->response_started, 0, 'a disconnect before any send leaves response_started 0';

done_testing;
