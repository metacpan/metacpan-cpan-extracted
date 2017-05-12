package Net::IMAP::Server;

use warnings;
use strict;

use base qw/Net::Server::Coro Class::Accessor/;

use UNIVERSAL::require;
use Coro;
use 5.008_008;

our $VERSION = '1.39';

=head1 NAME

Net::IMAP::Server - A single-threaded multiplexing IMAP server
implementation, using L<Net::Server::Coro>.

=head1 SYNOPSIS

  use Net::IMAP::Server;
  Net::IMAP::Server->new(
      port        => 193,
      ssl_port    => 993,
      auth_class  => "Your::Auth::Class",
      model_class => "Your::Model::Class",
      user        => "nobody",
      group       => "nobody",
  )->run;

=head1 DESCRIPTION

This model provides a complete implementation of the C<RFC 3501>
specification, along with several IMAP4rev1 extensions.  It provides
separation of the mailbox and message store from the client
interaction loop.

Note that, following RFC suggestions, login is not allowed except
under either SSL or TLS.  Thus, you are required to have a F<certs/>
directory under the current working directory, containing files
F<server-cert.pem> and C<server-key.pem>.  Failure to do so will cause
the server to fail to start.  Note that if the default paths suit your
needs, you can specify different ones using the L</server_cert> and
L</server_key> arguments to L</new>.

=head1 INTERFACE

The primary method of using this module is to supply your own model
and auth classes, which inherit from
L<Net::IMAP::Server::DefaultModel> and
L<Net::IMAP::Server::DefaultAuth>.  This allows you to back your
messages from arbitrary data sources, or provide your own
authorization backend.  For the most part, the implementation of the
IMAP components should be opaque.

=head1 METHODS

=cut

__PACKAGE__->mk_accessors(
    qw/port ssl_port
       auth_class model_class connection_class
       command_class
       poll_every
       unauth_idle auth_idle unauth_commands
      /
);

=head2 new PARAMHASH

Creates a new IMAP server object.  This doesn't even bind to the
sockets; it merely initializes the object.  It will C<die> if it
cannot find the appropriate certificate files.  Valid arguments to
C<new> include:

=over

=item port

The port to bind to.  Defaults to port 1430.

=item ssl_port

The port to open an SSL listener on; by default, this is disabled, and
any true value enables it.

=item auth_class

The name of the class which implements authentication.  This must be a
subclass of L<Net::IMAP::Server::DefaultAuth>.

=item model_class

The name of the class which implements the model backend.  This must
be a subclass of L<Net::IMAP::Server::DefaultModel>.

=item connection_class

On rare occasions, you may wish to subclass the connection class; this
class must be a subclass of L<Net::IMAP::Server::Connection>.

=item poll_every

How often the current mailbox should be polled, in seconds; defaults
to 0, which means it will be polled after every client command.

=item unauth_commands

The number of commands before unauthenticated users are disconnected.
The default is 10; set to zero to disable.

=item unauth_idle

How long, in seconds, to wait before disconnecting idle connections
which have not authenticated yet.  The default is 5 minutes; set to
zero to disable (which is not advised).

=item auth_idle

How long, in seconds, to wait before disconnecting authenticated
connections.  By RFC specification, this B<must> be longer than 30
minutes.  The default is an hour; set to zero to disable.

=item server_cert

Path to the SSL certificate that the server should use.  This can be
either a relative or absolute path.

=item server_key

Path to the SSL certificate key that the server should use.  This can
be either a relative or absolute path.

=back

It also accepts the following L<Net::Server> arguments -- see its
documentation for details on their use.

=over

=item L<Net::Server/log_level>

=item L<Net::Server/log_file>

=item L<Net::Server/syslog_logsock>

=item L<Net::Server/syslog_ident>

=item L<Net::Server/syslog_logopt>

=item L<Net::Server/syslog_facility>

=item L<Net::Server/pid_file>

=item L<Net::Server/chroot>

=item L<Net::Server/user>

=item L<Net::Server/group>

=item L<Net::Server/reverse_lookups>

=item L<Net::Server/allow>

=item L<Net::Server/deny>

=item L<Net::Server/cidr_allow>

=item L<Net::Server/cidr_deny>

=back

=cut

sub new {
    my $class = shift;

    my $self = Class::Accessor::new(
        $class,
        {   port             => 1430,
            ssl_port         => 0,
            auth_class       => "Net::IMAP::Server::DefaultAuth",
            model_class      => "Net::IMAP::Server::DefaultModel",
            connection_class => "Net::IMAP::Server::Connection",
            poll_every       => 0,
            unauth_idle      => 5*60,
            auth_idle        => 60*60,
            unauth_commands  => 10,
            @_,
            command_class    => {},
            connection       => {},
        }
    );

    $self->{server}{$_} = $self->{$_}
        for grep {defined $self->{$_}}
            qw/log_level log_file
               syslog_logsock syslog_ident syslog_logopt syslog_facility
               pid_file chroot user group
               reverse_lookups allow deny cidr_allow cidr_deny
              /;

    UNIVERSAL::require( $self->auth_class )
        or die "Can't require auth class: $@\n";
    $self->auth_class->isa("Net::IMAP::Server::DefaultAuth")
        or die
        "Auth class (@{[$self->auth_class]}) doesn't inherit from Net::IMAP::Server::DefaultAuth\n";

    UNIVERSAL::require( $self->model_class )
        or die "Can't require model class: $@\n";
    $self->model_class->isa("Net::IMAP::Server::DefaultModel")
        or die
        "Model class (@{[$self->model_class]}) doesn't inherit from Net::IMAP::Server::DefaultModel\n";

    UNIVERSAL::require( $self->connection_class )
        or die "Can't require connection class: $@\n";
    $self->connection_class->isa("Net::IMAP::Server::Connection")
        or die
        "Connection class (@{[$self->connection_class]}) doesn't inherit from Net::IMAP::Server::Connection\n";

    return $self;
}

=head2 run

Starts the server; this method shouldn't be expected to return.
Within this method, C<$Net::IMAP::Server::Server> is set to the object
that this was called on; thus, all IMAP objects have a way of
referring to the server -- and though L</connection>, whatever parts
of the IMAP internals they need.

Any arguments are passed through to L<Net::Server/run>.

=cut

sub run {
    my $self  = shift;
    my @proto = qw/TCP/;
    my @port  = $self->port;
    if ( $self->ssl_port ) {
        push @proto, "SSL";
        push @port,  $self->ssl_port;
    }
    local $Net::IMAP::Server::Server = $self;
    $self->SUPER::run(
        @_,
        proto => \@proto,
        port  => \@port,
    );
}

=head2 process_request

Accepts a client connection; this method is needed for the
L<Net::Server> infrastructure.

=cut

sub process_request {
    my $self   = shift;
    my $handle = $self->{server}{client};
    my $conn   = $self->connection_class->new(
        io_handle => $handle,
        server    => $self,
    );
    $self->connection($conn);
    $conn->handle_lines;
}

=head2 DESTROY

On destruction, ensure that we close all client connections and
listening sockets.

=cut

DESTROY {
    my $self = shift;
    $_->close for grep { defined $_ } @{ $self->connections };
    $self->server_close;
}

=head2 connections

Returns an arrayref of L<Net::IMAP::Server::Connection> objects which
are currently connected to the server.

=cut

sub connections {
    my $self = shift;
    return [ values %{$self->{connection}} ];
}

=head2 connection

Returns the currently active L<Net::IMAP::Server::Connection> object,
if there is one.  This is determined by examining the current
coroutine.

=cut

sub connection {
    my $class = shift;
    my $self  = ref $class ? $class : $Net::IMAP::Server::Server;
    if (@_) {
        if (defined $_[0]) {
            $self->{connection}{$Coro::current . ""} = shift;
        } else {
            delete $self->{connection}{$Coro::current . ""};
        }
    }
    return $self->{connection}{$Coro::current . ""};
}

=head2 concurrent_mailbox_connections [MAILBOX]

This can be called as either a class method or an instance method; it
returns the set of connections which are concurrently connected to the
given mailbox object (which defaults to the current connection's
selected mailbox)

=cut

sub concurrent_mailbox_connections {
    my $class    = shift;
    my $self     = ref $class ? $class : $Net::IMAP::Server::Server;
    my $selected = shift || $self->connection->selected;

    return () unless $selected;
    return
        grep { $_->is_auth and $_->is_selected and $_->selected eq $selected }
        @{ $self->connections };
}

=head2 concurrent_user_connections [USER]

This can be called as either a class method or an instance method; it
returns the set of connections whose
L<Net::IMAP::Server::DefaultAuth/user> is the same as the given
L<USER> (which defaults to the current connection's user)

=cut

sub concurrent_user_connections {
    my $class = shift;
    my $self  = ref $class ? $class : $Net::IMAP::Server::Server;
    my $user  = shift || $self->connection->auth->user;

    return () unless $user;
    return
        grep { $_->is_auth and $_->auth->user eq $user }
        @{ $self->connections };
}

=head2 capability

Returns the C<CAPABILITY> string for the server.  This string my be
modified by the connection before being sent to the client (see
L<Net::IMAP::Server::Connection/capability>).

=cut

sub capability {
    my $self = shift;
    return "IMAP4rev1 STARTTLS CHILDREN LITERAL+ UIDPLUS ID NAMESPACE";
}

=head2 id

Returns a hash of properties to be conveyed to the client, should they
ask the server's identity.

=cut

sub id {
    return (
        name    => "Net-IMAP-Server",
        version => $Net::IMAP::Server::VERSION,
    );
}

=head2 add_command NAME => PACKAGE

Adds the given command C<NAME> to the server's list of known commands.
C<PACKAGE> should be the name of a class which inherits from
L<Net::IMAP::Server::Command>.

=cut

sub add_command {
    my $self = shift;
    my ($name, $package) = @_;
    if (not $package->require) {
        $self->log( 1, $@ );
    } elsif (not $package->isa('Net::IMAP::Server::Command')) {
        $self->log( 1, "$package is not a Net::IMAP::Server::Command!" );
    } else {
        $self->command_class->{uc $name} = $package;
    }
}

=head2 log SEVERITY, MESSAGE

By default, defers to L<Net::Server/log>, which outputs to syslog, a
logfile, or STDERR, depending how it was configured.  L<Net::Server>'s
default is to print to STDERR.  If you have custom logging needs,
override this method, or L<Net::Server/write_to_log_hook>.

=cut

1;    # Magic true value required at end of module
__END__

=head1 Object model

An ASCII model of the relationship between objects is below.  In it,
single lines represent scalar values, and lines made of other
characters denote array references or relations.

   +----------------------------------------------+
   |                                              |
   |                    Server                    |
   |                                              |
   +1-----2---------------------------------------+
    #     |      ^         ^            ^        ^
    #     |      |         |            |        |
    #     v      |         |            |        |
    #   +--------1-------+ |     +------1------+ |
    ###>|   Connection   |<------2   Command   | |
    #   +--4-----3------2+ |     +-------------+ |
  ,-#------'     |      `--------------.         |
  | #            v         |           v         |
  | #   +----------------+ |     +-------------+ |
  | #   |     Model      2------>|    Auth     | |
  | #   +--------1-------+ |     +-------------+ |
  | #            `---------------------------------.
  | #                      |                     | |
  | #                  ,---'                 ,---' |
  | #   +--------------1-+       +-----------1-+   |
  | ###>|   Connection   |<------2   Command   |   |
  |     +--4-5---3------2+       +-------------+   |
  | ,------' *   |      `--------------.           |
  | | ********   v                     v           |
  | | * +----------------+       +-------------+   |
  | | * |     Model      2------>|    Auth     |   |
  | | * +--------1-------+       +-------------+   |
  | | *          |                                 |
  | | *          |  ,------------------------------'
  | | *          |  |           ^ SERVER
 .|.|.*..........|..|................................
  | | *          |  |           v MODEL
  | | *          v  v
  | '-*---->+-------------+<------------.
  '---*---->|   Mailbox   |<----------. |
      *     +-1------2-3--+<----.     | |
      *       @   ^  $ %        |     | |
      *       @   |  $$$$>+-----1---+ | |
      *       @   |  $ %  |         | | |
      *       @   |  $ %%>| Message | | |
      *       @   |  $ %  |         | | |
      ********@***|******>+---------+ | |
      *       @   |  $ %              | |
      *       @   |  $$$$>+---------+ | |
      *       @   |    %  |         | | |
      *       @   |    %%>| Message 1-' |
      *       @   |       |         |   |
      ********@***|******>+---------+   |
      *       @   |                     |
      *       @   |       +---------+   |
      *       @   |       | Message 1---'
      ********@***|******>+---------+
              @   |
              @  +4----------+
              @@>|  Mailbox  |
                 +-----------+

The top half consists of the parts which implement the IMAP protocol
itself; the bottom contains the models for the backing store.  Note
that, for the most part, the backing store is unaware of the framework
of the server itself.

Each model has references to others, as follows:

=over

=item Server

Contains references to the set of C<connections> (1).  It also has a
sense of the I<current> C<connection> (2), based on the active L<Coro>
thread.

=item Connection

Connections hold a reference to their C<server> (1).  If the
connection has authenticated, they hold a reference to the C<auth>
object (2), and to their C<model> (3).  If a mailbox is C<selected>
(4), they hold a pointer to that, as well.  Infrequently, the
connection will need to temporarily store references to the set of
C<temporary_messages> (5) which have been expunged in other
connections, but we have been unable to notify this connection of.

=item Command

Commands store their C<server> (1) and C<connection> (2).

=item Model

Models store a reference to the C<root> (1) of their mailbox tree, as
well as to the C<auth> (2) which gives them access to such.

=item Mailbox

Mailboxes store a list of C<children> mailboxes (1), and C<messages>
(2) contained within them, which are stored in sequence order.  They
also contain a hash of C<uids> (3) for fast UID retrieval of
messages. If they are not the root mailbox, they also store a
reference to their C<parent> mailbox (4).

=item Message

Messages store the C<mailbox> (1) in which they are contained.

=back

=head1 DEPENDENCIES

L<Coro>, L<Net::Server::Coro>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-imap-server@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

A low-traffic mailing list exists for discussion on how to (ab)use
this module, at
L<http://lists.bestpractical.com/cgi-bin/mailman/listinfo/net-imap-server>.

=head1 AUTHOR

Alex Vandiver  C<< <alexmv@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Best Practical Solutions, LLC.  All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
