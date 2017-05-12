package MyClient;

BEGIN
{
	use strict;
	use SafePaths;
	use base qw(Aw::Client);

	use vars qw($AW_TIMEOUT);

	$AW_TIMEOUT = 10000;
}


#
#  The only reason to override publish here is to more readily
#  be able to tweak the $AW_TIME value, return a hash reference, 
#  and handle errors simply.
#
sub publish
{
my ($self, $request, $timeout) = @_ ;


	my $event = undef;
	$event    = ( $self->SUPER::publish ( $request ) )
	          ? undef
	          : $self->getEvent ( $timeout || $AW_TIMEOUT );

	return ( {errorText => "NullReply"} ) if ( !$event || $event->isNullReply );

	my %hash  = $event->toHash;
	$event->delete;
	$event    = undef;


	\%hash;
}



package AwGateway;



BEGIN
{
	use strict;
	require Aw::Event;
	require SOAP::Lite;

	use vars qw(@ISA);
	@ISA = qw(SOAP::Server::Parameters);
}



sub relay
{
my $self         = shift;
my %requestEvent = %{$_[0]};


	my $uri        = new URI ( $_[1]->namespaceuriof( '//relay' ) );
	my $authority  = $uri->authority;

	my $event_type = $requestEvent{_event_type};
	my $timeout    = ( $requestEvent{_event_timeout} ) ? $requestEvent{_event_timeout} : 0 ;

	my ( $broker, $client_group, $host ) = $authority =~ m/(\w+):?(\w+)?@(.*)/;

	my $client = new MyClient ( $host, $broker, "", $client_group, "SOAP::Client" );

	return "$!\n" unless $client;

	my $event = new Aw::Event ( $client, $event_type, \%requestEvent );

	return "$!\n" unless $event;

	$client->publish ( $event, $timeout );
}

1;

__END__

=head1 NAME

AwGateway - A SOAP Gateway into ActiveWorks Event Space

=head1 SYNOPSIS

use SOAP::Lite +autodispatch =>
  uri => 'activeworks://myAwBroker:MyClientGroup@my.active.host:7449',
  proxy => 'http://my.proxy.server/soap/',
  on_fault => sub { my($soap, $res) = @_;
    die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
  }
;



=head1 DESCRIPTION

AwGateway provides a simple means to convert a SOAP request into an ActiveWorks
event.  AwGateway is also a light weight alternative to the more comprehensive
SOAP::Transport::ACTIVEWORKS module (which is not required).  The AwGateway
class provides a single method, B<relay>, which must be passed a HASH reference
that matches the structure of the ActiveWorks event type specified in the
required '_event_type' field of the hash:


my %user               =(
                                         # required!
    _event_type        => "Ac::UserNameQueryRequest",
    _event_timeout     => 150000,        # optional
    strUserName        => $ARGV[0],
    strISP             => "some_isp.net",
    strFirstName       => "John",
    strLastName        => "Doe",
    strCustomerNumber  => "7654321",
 );


my %reply = %{ AwGateway->SOAP::relay ( \%user ) } or
    die ( "User \"$user{strUserName}\" has no Account." );


=head1 AUTHOR

Daniel Yacob, L<yacob@rcn.com|mailto:yacob@rcn.com>

=head1 SEE ALSO

S<perl(1). SOAP::Lite(3). SOAP::Transport::ACTIVEWORKS(3).>

=cut
