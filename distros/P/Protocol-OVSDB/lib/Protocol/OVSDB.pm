
use v5.36;
use experimental qw( class signatures );

class Protocol::OVSDB v0.99.0;

=head1 NAME

Protocol::OVSDB - Implementation of RFC 7047 (Open vSwitch Database Management protocol)

=head1 SYNOPSIS

  use Protocol::OVSDB;
  use IO::Socket::IP;

  my $sock = IO::Socket::IP->new( '127.0.0.1:6640' );
  my $ovsdb = Protocol::OVSDB->new(
     on_send => sub { syswrite( $sock, $_[0] ); },
     on_result_response => sub { say 'Yay!' },
     on_error_response => sub { say 'Nope...' }
  );
  $sock->connect;

  $ovsdb->list_dbs( sub { say $_ for $_[0]->@* } );
  sysread( $sock, my $buf, 10240 );
  $ovsdb->receive( $buf );

=head1 DESCRIPTION

This module implements the Open vSwitch (OVS) Database Management protocol. It can
be used to query OVS or OVN databases, or listen for updates. New databases can be
developed using the OVSDB database engine. The module provides all methods required
to insert and modify data in such databases.

In line with other modules in the Protocol::* namespace, this module does not handle
the actual connection. Requests to send data are handled through the C<on_send>
callback.

B<NOTE> The OVS project encourages the use of their CLI tools to update data in the
database, because those tools ensure validity of the database. Those validations
are I<not> in the server. Updates coming from this module won't be validated.

=cut

use JSON::PP;

my $json = JSON::PP->new->utf8->canonical;

field $_next_id  = 1;
field $_pending  = {};
field $_monitors = {};
field $_locks    = {};

=head1 CONSTRUCTORS

=head2 new

  $ovsdb = Protocol::OVSDB->new( %params );

Creates a new OVSDB protocol handler instance with C<%params>.
Recognized parameters are:

=over 8

=item * C<on_send> (required)

  sub on_send( $data ) { ... }

A callback triggered when data is to be sent.

=item * C<on_notification>

  sub on_notification( $method, $params ) { ... }

A callback triggrered when a notification is received.

=item * C<on_request>

  sub on_request( $method, $params, $id ) { ... }

A callback triggered when a request is received. This
only applies when the instance is used as a server; clients
won't see this callback being triggered.

=back

=cut

# transmission
field $_on_send              :param(on_send);

# event handling
field $_on_notification      :param = sub {};
field $_on_request           :param = sub {};

method _handle_message($msg) {
    my $id = $msg->{id};
    if (not defined $id) {
        # notification
        my $method = $msg->{method} // '';
        if ($method eq 'update') {
            # monitor notification
            my ($monitor_id, $table_updates) = $msg->{params}->@*;
            my $monitor = $_monitors->{$monitor_id};
            $monitor->notify($table_updates);
        }
        elsif ($method eq 'locked'
               or $method eq 'stolen') {
            # lock notification
            my ($lock_id) = $msg->{params}->@*;
            my $lock = $_locks->{$lock_id};
            $lock->notify( $method eq 'locked', $method );
        }
        else {
            $_on_notification->( $msg->{method}, $msg->{params} );
        }
    }
    elsif (defined $msg->{result}) {
        # result response
        my $cb = delete $_pending->{$id};
        $cb->( $msg->{result}, undef );
    }
    elsif (defined $msg->{error}) {
        # error response
        my $cb = delete $_pending->{$id};
        $cb->( undef, $msg->{error} );
    }
    else {
        # request
        $_on_request->( $msg->{method}, $msg->{params}, $id );
    }
}

method _send($msg) {
    $_on_send->($json->encode( $msg ));
}

=head1 INPUT METHODS

=head2 receive

  $ovsdb->receive( $data );

Receives data from a connection and decodes it into
protocol messages.

=cut

method receive($data) {
    $json->incr_parse($data);
    while (my $msg = $json->incr_parse ) {
        $self->_handle_message( $msg );
    }
    return;
}

=head1 BASIC PROTOCOL METHODS

=head2 send_notification

  $ovsdb->send_notification( $method, $params );

Sends a notification to the connected party. Notifications typically
name the methods C<stolen>, C<locked> or C<update>.

=cut

method send_notification($method, $params) {
    $self->_send( { method => $method, params => $params // [] } );
}

=head2 send_request

  my $id = $ovsdb->send_request( $method, $params, $cb );

Sends a request to the server, returning the C<$id>. This C<$id>
can later be used to cancel outstanding requests, where applicable.

=cut

method send_request($method, $params, $cb) {
    my $id = $_next_id++;
    $_pending->{$id} = $cb;
    my $msg = {
        method => $method,
        params => $params // [],
        id => $id
    };
    $self->_send( $msg );

    return $id;
}

=head2 send_result

  $ovsdb->send_result( $result, $id );

Either this method or C<send_error> should be used to respond
to a received request. This method sends a message indicating
succesfull completion of the request.

=cut

method send_result($result, $id) {
    $self->_send( { result => $result, id => $id } );
}

=head2 send_error

  $ovsdb->send_error( $error, $id );

Either this method or C<send_result> should be used to respond
to a received request. This method sends a message indicating
failed completion of the request.

=cut

method send_error($error, $id) {
    $self->_send( { error => $error, id => $id } );
}

=head1 FUNCTIONAL RPC METHODS

=head2 list_dbs

  $ovsdb->list_dbs( sub($dbs, $error) { ... } );

Sends a request to the server to list available databases
in the connected database engine. Either C<$dbs> or
C<$error> is defined.

=cut

method list_dbs( $cb ) {
    return $self->send_request( 'list_dbs', [], $cb );
}

=head2 get_schema

  $ovsdb->get_schema( $db, sub($schema, $error) { ... } );

Sends a request to the server to list the database schema
for the given database. Either C<$schema> or C<$error> is defined.

=cut

method get_schema( $db, $cb ) {
    return $self->send_request( 'get_schema', [ $db ], $cb );
}

=head2 transact

  my $transact_id = $ovsdb->transact( $db, $ops, $cb );

Sends a request to the server to execute a series of
operations.

=cut

method transact( $db, $ops, $cb ) {
    return $self->send_request( 'transact', [ $db, $ops->@* ], $cb );
}

=head2 cancel

  $ovsdb->cancel( $transact_id );

This sends a notification to the server that the currently running
C<transact> call needs to be cancelled.

=cut

method cancel( $transact_id, $cb ) {
    return $self->send_notification( 'cancel', [ $transact_id ], $cb );
}

=head2 monitor

  $ovsdb->monitor( $db, $monitor, $monitor_requests, sub($monitor, $error) { ... } );

Sends a set of monitoring requests to the server. C<$monitor> must be an instance of
L<Protocol::OVSDB::Monitor>. The callback is called with the result of the RPC request.
Either C<$monitor> or C<$error> is defined.

The initial update notification is the entire table content matching the update queries,
when the monitoring request requires one.

Monitoring started by this function can be stopped using the C<cancel> method in the monitor:

  $monitor->cancel( $cb );

=cut

method monitor( $db, $monitor, $requests, $cb ) {
    $monitor->_set_conn( $self );
    return $self->send_request(
        'monitor',
        [ $db, $monitor->id, $requests ],
        sub($table_updates, $error) {
            if (defined $error) {
                $cb->(undef, $error);
                return;
            }
            $_monitors->{$monitor->id} = $monitor;
            $cb->( $monitor, undef );
            $monitor->notify( $table_updates );
            return;
        });
}

=head2 lock

  $ovsdb->lock( $lock, sub($result, $error) { ... } );

The C<$lock> is an instance of L<Protocol::OVSDB::Lock>. Note that locks are
server-wide, not restricted to a specific database.

If the lock could be acquired immediately, C<$result> contains a C<$locked>
key with a C<true> value. If the lock has I<not> been acquired (it's pending),
C<$result> contains a C<locked> key with a C<false> value. A C<locked>
notification is issued when the lock is finally acquired.

A lock acquired through this method can be released using C<$lock->unlock>.

=cut

method lock( $lock, $cb ) {
    $lock->_set_conn( $self );
    return $self->send_request(
        'lock',
        [ $lock->id ],
        sub($result, $error) {
            if (defined $error) {
                $cb->(undef, $error);
                return;
            }
            $_locks->{$lock->id} = $lock;
            $cb->( $lock, undef );
            $lock->notify( $result->{locked}, 'lock' );
        });
}

=head2 steal

  $ovsdb->steal( $lock, sub($result, $error) { ... } );

Instructs the server to assign this client the given lock,
even if owned by another client.

The current owner of the lock is sent a C<stolen> notification.

=cut

method steal( $lock, $cb ) {
    $lock->_set_conn( $self );
    return $self->send_request(
        'steal',
        [ $lock->id ],
        sub($result, $error) {
            if (defined $error) {
                $cb->(undef, $error);
                return;
            }
            $_locks->{$lock->id} = $lock;
            $cb->( $lock, undef );
            $lock->notify( $result->{locked}, 'stolen' );
        });
}

=head2 echo

  $ovsdb->echo( sub { ... } );

Checks if the connection is still active.

=cut

method echo( $cb ) {
    return $self->send_request( 'echo', [], $cb );
}

=head1 INTERNAL METHODS

=head2 remove_monitor

  $ovsdb->remove_monitor( $monitor_id );

=cut

method remove_monitor( $monitor_id ) {
    delete $_monitors->{$monitor_id};
    return;
}

=head2 remove_lock

=cut

method remove_lock( $lock_id ) {
    delete $_locks->{$lock_id};
    return;
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
