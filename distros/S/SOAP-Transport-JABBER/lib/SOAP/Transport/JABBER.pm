# ======================================================================
#
# Copyright (C) 2000-2001 Paul Kulchenko (paulclinger@yahoo.com)
# SOAP::Lite is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: JABBER.pm 353 2010-03-17 21:08:34Z kutterma $
#
# ======================================================================

package SOAP::Transport::JABBER;

use strict;
use warnings;

our $VERSION = 0.713;

use Net::Jabber 1.0021 qw(Client);
use URI::Escape;
use URI;

my $NAMESPACE = "http://namespaces.soaplite.com/transport/jabber";

{
    no warnings qw(redefine);
                                 # fix problem with printData in 1.0021
    *Net::Jabber::printData = sub { 'nothing' }
      if Net::Jabber->VERSION == 1.0021;

    # fix problem with Unicode encoding in EscapeXML.
    # Jabber ALWAYS converts latin to utf8
    *Net::Jabber::EscapeXML = *Net::Jabber::EscapeXML = # that's Jabber 1.0021
      *XML::Stream::EscapeXML =
      *XML::Stream::EscapeXML =                         # that's Jabber 1.0022
      \&SOAP::Utils::encode_data;

    # There is also an error in XML::Stream::UnescapeXML 1.12, but
    # we can't do anything there, except hack it also :(
}

# ======================================================================

package URI::jabber;    # ok, lets do 'jabber://' scheme
require URI::_server;
require URI::_userpass;
@URI::jabber::ISA = qw(URI::_server URI::_userpass);

# jabber://soaplite_client:soapliteclient@jabber.org:5222/soaplite_server@jabber.org/Home
# ^^^^^^   ^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^ ^^^^^^^^^^ ^^^^ ^^^^^^^^^^^^^^^^^^^^^^^^^^ ^^^^

# ======================================================================

package SOAP::Transport::JABBER::Query;
our $VERSION = 0.713;
sub new {
    my $proto = shift;
    bless {} => ref($proto) || $proto;
}

sub SetPayload {
    shift;
    Net::Jabber::SetXMLData( "single", shift->{QUERY}, "payload", shift, {} );
}

sub GetPayload {
    shift;
    Net::Jabber::GetXMLData( "value", shift->{QUERY}, "payload", "" );
}

# ======================================================================

package SOAP::Transport::JABBER::Client;
our $VERSION = 0.713;
use vars qw(@ISA);
@ISA = qw(SOAP::Client Net::Jabber::Client);

sub DESTROY { SOAP::Trace::objects('()') }

sub new {
    my $self = shift;

    unless ( ref $self ) {
        my $class = ref($self) || $self;
        my ( @params, @methods );
        while (@_) {
            $class->can( $_[0] )
              ? push( @methods, shift() => shift )
              : push( @params, shift );
        }
        $self = $class->SUPER::new(@params);
        while (@methods) {
            my ( $method, $params ) = splice( @methods, 0, 2 );
            $self->$method( ref $params eq 'ARRAY' ? @$params : $params );
        }
        SOAP::Trace::objects('()');
    }
    return $self;
}

sub endpoint {
    my $self = shift;

    return $self->SUPER::endpoint unless @_;

    my $endpoint = shift;

    # nothing to do if new endpoint is the same as current one
    return $self
      if $self->SUPER::endpoint && $self->SUPER::endpoint eq $endpoint;

    my $uri = URI->new($endpoint);
    my ( $undef, $to, $resource ) = split m!/!, $uri->path, 3;
    $self->Connect(
        hostname => $uri->host,
        port     => $uri->port,
    ) or Carp::croak "Can't connect to @{[$uri->host_port]}: $!";

    my @result = $self->AuthSend(
        username => $uri->user,
        password => $uri->password,
        resource => 'soapliteClient',
    );
    $result[0] eq "ok"
      or Carp::croak "Can't authenticate to @{[$uri->host_port]}: @result";

    $self->AddDelegate(
        namespace  => $NAMESPACE,
        parent     => 'Net::Jabber::Query',
        parenttype => 'query',
        delegate   => 'SOAP::Transport::JABBER::Query',
    );

    # Get roster and announce presence
    $self->RosterGet();
    $self->PresenceSend();

    $self->SUPER::endpoint($endpoint);
}

sub send_receive {
    my ( $self, %parameters ) = @_;
    my ( $envelope, $endpoint, $encoding ) =
      @parameters{qw(envelope endpoint encoding)};

    $self->endpoint( $endpoint ||= $self->endpoint );

    my ( $undef, $to, $resource ) = split m!/!, URI->new($endpoint)->path, 3;

    # Create a Jabber info/query message
    my $iq = new Net::Jabber::IQ();
    $iq->SetIQ(
        type => 'set',
        to   => join '/',
        $to => $resource || 'soapliteServer',
    );
    my $query = $iq->NewQuery($NAMESPACE);
    $query->SetPayload($envelope);

    SOAP::Trace::debug($envelope);

    my $iq_rcvd = $self->SendAndReceiveWithID($iq);
    my ($query_rcvd) = $iq_rcvd->GetQuery($NAMESPACE)
      if $iq_rcvd;    # expect only one
    my $msg = $query_rcvd->GetPayload() if $query_rcvd;

    SOAP::Trace::debug($msg);

    my $code = $self->GetErrorCode();

    $self->code($code);
    $self->message($code);
    $self->is_success( !defined $code || $code eq '' );
    $self->status($code);

    return $msg;
}

# ======================================================================

package SOAP::Transport::JABBER::Server;
our $VERSION = 0.713;
use Carp ();
use vars qw(@ISA $AUTOLOAD);
@ISA = qw(SOAP::Server);

sub new {
    my $self = shift;

    unless ( ref $self ) {
        my $class = ref($self) || $self;
        my $uri = URI->new(shift);
        $self = $class->SUPER::new(@_);

        $self->{_jabberserver} = Net::Jabber::Client->new;
        $self->{_jabberserver}->Connect(
            hostname => $uri->host,
            port     => $uri->port,
        ) or Carp::croak "Can't connect to @{[$uri->host_port]}: $!";

        my ( $undef, $resource ) = split m!/!, $uri->path, 2;
        my @result = $self->AuthSend(
            username => $uri->user,
            password => $uri->password,
            resource => $resource || 'soapliteServer',
        );
        $result[0] eq "ok"
          or Carp::croak
          "Can't authenticate to @{[$uri->host_port]}: @result";

        $self->{_jabberserver}->SetCallBacks(
            iq => sub {
                shift;
                my $iq = new Net::Jabber::IQ(@_);

                my ($query) = $iq->GetQuery($NAMESPACE);    # expect only one
                my $request = $query->GetPayload();

                SOAP::Trace::debug($request);

                # Set up response
                my $reply = $iq->Reply;
                my $x     = $reply->NewQuery($NAMESPACE);

                my $response = $self->SUPER::handle($request);
                $x->SetPayload($response);

                # Send response
                $self->{_jabberserver}->Send($reply);
            } );

        $self->AddDelegate(
            namespace  => $NAMESPACE,
            parent     => 'Net::Jabber::Query',
            parenttype => 'query',
            delegate   => 'SOAP::Transport::JABBER::Query',
        );

        $self->RosterGet();
        $self->PresenceSend();
    }
    return $self;
}

sub AUTOLOAD {
    my $method = substr( $AUTOLOAD, rindex( $AUTOLOAD, '::' ) + 2 );
    return if $method eq 'DESTROY';

    no strict 'refs';
    *$AUTOLOAD = sub { shift->{_jabberserver}->$method(@_) };
    goto &$AUTOLOAD;
}

sub handle {
    shift->Process();
}

# ======================================================================

1;

__END__

=head1 SOAP::Transport::JABBER

This class provides a Jabber-based transport backend for SOAP::Lite.

This class uses the Net::Jabber classes to abstract the Jabber
protocol away from the direct notice of the application. Besides maintaining
any needed objects internally, the package also uses a separate class as a
proxy between communication layers, SOAP::Transport::JABBER::Query. The
Jabber support provides both client and server classes.

=head2 SOAP::Transport::JABBER::Client

Inherits from: L<SOAP::Client>, L<Net::Jabber::Client>.
This class provides localized implementations for both the new and
send_receive methods, neither of which are changed in terms of interface.
The only difference is that the send_receive method doesn't directly use
the action hash key on the input it receives. In addition to these two basic
methods, the server class overrides the endpoint
method it would otherwise inherit from SOAP::Client:

=over

=item endpoint

In the general sense, this still acts as a basic accessor method, with the
same get value/set value behavior used consistently through the SOAP::Lite
module. The difference between this version and most others is that when the
endpoint is initially set or is changed, the client object makes the
connection to the Jabber endpoint, sending the proper authentication
credentials and setting up the conversation mechanism using the
SOAP::Transport::JABBER::Query class as a delegate. It then calls the
superclass endpoint method to ensure that all other related elements are
taken care of.

=back

=head2 SOAP::Transport::JABBER::Server

Inherits from: L<SOAP::Server>.

The server class provided for Jabber support defines a slightly different
interface to the constructor. The server manages the Jabber communication
by means of an internal Net::Jabber::Client instance. In a fashion similar
to that used by SOAP::Transport::HTTP::Daemon, the server class catches
methods that are meant for the Jabber client and treats them as if the class
inherits directly from that class, without actually doing so. In doing so,
the handle method is implemented as a frontend to the Process method of the
Jabber client class. The difference in the interface to the constructor is:

=over

=item new(I<URI>, I<optional server key/value options>)

    $srv = SOAP::Transport::JABBER::Server-> new($uri);

The constructor for the class expects that the first argument will be a
Jabber-style URI, followed by the standard set of optional key/value pairs
of method names and their parameters. All the method/parameter
pairs are delegated to the superclass constructor; only the Jabber URI is
handled locally. It's used to set up the Net::Jabber::Client instance that
manages the actual communications.

=back

=head1 BUGS

This module is currently unmaintained, so if you find a bug, it's yours -
you probably have to fix it yourself. You could also become maintainer -
just send an email to mkutter@cpan.org

=head1 AUTHORS

Paul Kulchenko (paulclinger@yahoo.com)

Randy J. Ray (rjray@blackperl.com)

Byrne Reese (byrne@majordojo.com)

Martin Kutter (martin.kutter@fen-net.de)

=cut
