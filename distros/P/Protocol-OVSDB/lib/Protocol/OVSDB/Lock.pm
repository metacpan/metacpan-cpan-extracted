
use v5.36;
use experimental qw( class signatures );

class Protocol::OVSDB::Lock v0.99.0;

=head1 NAME

Protocol::OVSDB::Lock - A lock in an Open vSwitch database

=head1 SYNOPSIS

  use experimental qw( signatures );

  my $lock = Protocol::OVSDB::Lock->new(
    id => 'your-lock-name',
    on_update => sub { ... }
  );
  $ovsdb->lock( $lock, sub($, $error) { die $error if $error } );
  $lock->unlock;

  $lock->reset;
  $ovsdb->steal( $lock, sub($, $error) { die $error if $error } );

=head1 DESCRIPTION

This module provides an interface to locks in the OVSDB server. When
it goes out of scope, the underlying lock in the OVSDB will be unlocked.

=head1 CONSTRUCTORS

=head2 new

  my $lock = Protocol::OVSDB::Lock->new( %args );

The following arguments are recognized:

=over 8

=item * C<on_update>

  sub on_update( $locked, $reason );

Callback invoked when the server sends an update notification. The
first invocation is the initial response sending the full table
content.

=back

=cut

use builtin qw( true false weaken );
no warnings qw( experimental::builtin );


field $_conn = undef;
field $_id :param(id);
field $_pending = undef;
field $_locked = false;

# event callbacks
field $_on_update :param(on_update) = sub {};


method id() {
    $_id;
}

method _set_conn($conn) {
    $_conn = $conn;
    weaken $_conn;
}


=head2 reset

  $lock->reset;

Resets the lock's state so it can be used as the argument to a C<lock> or C<steal>
call again.

=cut

method reset() {
    $_conn = undef;
    $_pending = undef;
    $_locked = false;
}

=head2 unlock

  $lock->unlock( sub { ... } );

Releases the lock.

B<Note> The lock is not reusable with an L<Protocol::OVSDB> C<lock> or C<steal>
call until the C<reset> method has been called to reset the lock state.
=cut

sub _null_cb {}

method unlock( $cb = \&_null_cb ) {
    return unless $_conn;

    my $conn = $_conn;
    $_conn = undef;
    $conn->send_request(
        'unlock',
        [ $_id ],
        sub($result, $error) {
            if (defined $result) {
                $conn->remove_lock( $_id );
                $_on_update->( false, 'unlock' );
            }
            $cb->($result, $error);
        });
    return;
}

=head2 notify

  $monitor->notify( $locked, $reason );

Sends an update for C<$locked> to the C<on_update> callback, stating
the reason for the update in C<$reason>.

=cut

method notify( $locked, $reason ) {
    if ($reason eq 'lock') {
        $_pending = not $locked;
    }
    else {
        $_pending = false;
    }
    $_locked = $locked;
    $_on_update->( $locked, $reason );
}

=head2 DESTROY

=cut

method DESTROY() {
    return unless $_conn;
    $self->unlock;
}

1;

=head1 AUTHOR

=over 8

=item * Erik Huelsmann C<< <ehuels@gmail.com> >>

=back

=head1 SEE ALSO

L<RFC 7047|https://www.rfc-editor.org/rfc/rfc7047.html>

=head1 LICENSE AND COPYRIGHT

See the LICENSE file in this distribution.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR
THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.
