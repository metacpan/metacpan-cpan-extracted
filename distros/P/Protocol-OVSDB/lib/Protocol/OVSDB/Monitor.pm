
use v5.36;
use experimental qw( class signatures );

class Protocol::OVSDB::Monitor v0.99.1;

=head1 NAME

Protocol::OVSDB::Monitor - Monitoring an Open vSwitch database

=head1 SYNOPSIS

  use experimental qw( signatures );

  my $monitor = Protocol::OVSDB::Monitor->new(
    on_update => sub { ... }
  );
  $ovsdb->monitor( 'Open_vSwitch', $monitor,
                   { 'Port'         => { 'select' => { initial => \1 } },
                     'Open_vSwitch' => { 'select' => { initial => \1 } } },
                   sub($, $error) { die $error if $error; });

=head1 DESCRIPTION

This module provides an interface to monitoring of OVSDB table content. When
it goes out of scope, the underlying monitor in the OVSDB will be canceled.

=head1 CONSTRUCTORS

=head2 new

  my $monitor = Protocol::OVSDB::Monitor->new( %args );

The following arguments are recognized:

=over 8

=item * C<on_update>

  sub on_update( @table_updates );

Callback invoked when the server sends an update notification. The
first invocation is the initial response sending the full table
content.

=back

=cut


my $next_id = 1;

field $_conn = undef;
field $_id = $next_id++;

# event callbacks
field $_on_update :param(on_update);

method id() {
    $_id;
}

method _set_conn($conn) {
    $_conn = $conn;
}


=head2 cancel

  $monitor->cancel( sub($result, $error) { ... } );

Ends the subscription to update notifications for
data modifications. The callback is optional.

=cut

sub _null_cb {}

method cancel( $cb = \&_null_cb ) {
    return unless $_conn;
    my $conn = $_conn;
    $_conn = undef;

    $conn->send_request(
        'monitor_cancel',
        $_id,
        sub($result, $error) {
            $conn->remove_monitor( $_id );
            $cb->($result, $error);
        });
}

=head2 notify

  $monitor->notify( $updates );

Sends C<$updates> to the C<on_update> callback.

=cut

method notify( $updates ) {
    $_on_update->( $updates );
}

=head1 DESTRUCTORS

=head2 DESTROY

Called by Perl internally when the monitor goes out of scope. If the
monitor is still active, this cancels the monitor.

=cut

method DESTROY() {
    return unless $_conn;
    $self->cancel;
}

1;

=head1 AUTHOR

=over 8

=item * Erik Huelsmann C<< <ehuels@gmail.com> >>

=back

=head1 SEE ALSO

L<Protocol::OVSDB>, L<RFC 7047|https://www.rfc-editor.org/rfc/rfc7047.html>

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
