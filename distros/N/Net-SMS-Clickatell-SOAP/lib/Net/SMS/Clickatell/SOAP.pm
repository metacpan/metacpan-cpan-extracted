#$Id: SOAP.pm,v 1.1 2010/11/28 15:22:42 pfarr Exp $
package Net::SMS::Clickatell::SOAP;

=pod

=head1 NAME

Net::SMS::Clickatell::SOAP - SOAP interface to the Clickatell SMS service

=head1 DESCRIPTION

Pure Perl module to access the Clickatell Bulk SMS gateway 
using the SOAP protocol.

 use SMS::Clickatell::SOAP;

 my $sms = new SMS::Clickatell::SOAP(
	connection => (
		proxy => $PROXY_URL,
		service => $SERVICE_URL,
		verbose => $VERBOSE,
		user	=> $WS_USER,
		password => $WS_PASSWD,
		api_id => 123456
	)
 );

=head1 METHODS

=over

=cut

use 5.008008;
use strict;
use warnings;
use vars qw(@ISA $VERSION);
use SOAP::Lite;
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = (
	'all' => [
		qw(
		  delmsg
		  errorcode
		  getbalance
		  getmsgcharge
		  ping
		  querymsg
		  routecoverage
		  sendmsg
		  sessionid
		  )
	]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

use version; $VERSION = sprintf "0.%02d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g;

## Globals
my ( $VERBOSE, );

###############################################################################

=item $sms = new( api_id => $api_id, user => $user, password => $password );

Class constructor method instantiates a class object and initiates a connection
to the Clickatell service through the auth call.

 my $hSMS = new SMS::Clickatell::SOAP(
 	proxy   => $endpoint,
 	service => "${endpoint}?wsdl",
	verbose => 0
 );

where:

=over

=item proxy (optional)

SOAP connection parameter. See SOAP::Lite for further information. Defaults to
http://api.clickatell.com/soap/webservice.php.

=item service (optional)

SOAP connection parameter. See SOAP::Lite for further information. Defaults to
http://api.clickatell.com/soap/webservice.php?wsdl.

=item verbose

Verbosity level for debugging. Default is verbose=>0 (only error output).

=back

=cut

sub new {

	my ( $status, $session_id, $result, $proxy, $service, );

	my ( $class, %params ) = @_;
	$VERBOSE = $params{verbose};    # Easier and more readable as $VERBOSE

	## Set default connection parameters if they were not passed.
	if ( exists $params{'proxy'} && defined $params{'proxy'} ) {
		$proxy = $params{'proxy'};
	} else {
		$proxy = "http://api.clickatell.com/soap/webservice.php";
		$params{'proxy'} = $proxy;
	}
	if ( exists $params{'service'} && defined $params{'service'} ) {
		$service = $params{'service'};
	} else {
		$service = $proxy . '?wsdl';
		$params{'service'} = $service;
	}

	## Initialize our class object, bless it and return it
	my $self = {
		_status      => 0,        # Status of the connection (0 or 1)
		_som         => undef,    # Pointer to connection object
		_last_result => undef,    # Save the last result code
		_session_id  => undef,    # Session ID from Clickatell
		_params      => \%params, # Save the passed parms in our object instance
		_verbose => $params{'verbose'},
	};
	bless $self, $class;

	## Connect to the AlarmPoint web server
	print "Connecting to service at $params{proxy}... " if $VERBOSE;
	my $sms = new SOAP::Lite(
		proxy   => $proxy,
		service => $service,
	);

	## If the basic connection was made then establish a session and save
	## the SOAP object for later reference
	if ($sms) {
		print "connected!\n" if $VERBOSE;
		$self->{'_som'} = $sms;
	}

	return $self;
}

###############################################################################
## 	_checkResult()
##
##	Internal function to check the status of a SOAP method call
##
## Parameters
##	SOM object
##
## Returns
## 	This subroutine returns a string based on the SOAP result envelope.
## 	If all went well it should return "OK". If not then it will return
## 	either the faultcode (if a SOAP fault occurred) or the result
## 	string if there was a method error on the server side.

sub _checkResult {

	my ( $self, $response ) = @_;

	my $VERBOSE = $self->{'_verbose'};

	if ( $response->fault ) {
		printf STDERR "A %s fault has occurred: %s\n", $response->faultcode,
		  $response->faultstring;
		return $response->fault();
	} else {
		if ( ref( $response->result ) eq "" ) {
			printf STDERR "\tReceived response: '%s'\n", $response->result
			  if $VERBOSE > 1;
			$self->{'_last_result'} = $response->result;
			return $response->result;
		} elsif ( ref( $response->result ) eq "ARRAY" ) {
			my $return = '';
			foreach my $element ( @{ $response->result } ) {
				$return .= "$element; ";
				$self->{'_last_result'} = $return;
				return $return;
			}
		} else {
			return "WARNING: I don't know how to handle a '"
			  . ref( $response->result )
			  . "' result\n";
		}
	}

}

###############################################################################

=item $msg = $sms->errorCode( $code );

Convert a numeric error code to a text error message

where:

=over

=item $code 

numeric error code returned by the Clickatell API

=item $msg

associated text error message

=back

=cut

sub errorcode {

	my ( $self, $errorCode ) = @_;

	if ( ref($self) eq 'SCALAR' ) { $errorCode = $self }
	;    # Not called as an object

	## Codes as of version 1.1.8 of the Clickatell SOAP API specification
	my %codes = (
		'001' => 'Authentication failed',
		'002' => 'Unknown username or password',
		'003' => 'Session ID expired',
		'004' => 'Account frozen',
		'005' => 'Missing session ID',
		'007' => 'IP Lockdown violation',
		'101' => 'Invalid or missing parameters',
		'102' => 'Invalid user data header',
		'103' => 'Unknown API message ID',
		'104' => 'Unknown client message ID',
		'105' => 'Invalid destination address',
		'106' => 'Invalid source address',
		'107' => 'Empty message',
		'108' => 'Invalid or missing API ID',
		'109' => 'Missing message ID',
		'110' => 'Error with email message',
		'111' => 'Invalid protocol',
		'112' => 'Invalid message type',
		'113' => 'Maximum message parts',
		'114' => 'Cannot route message',
		'115' => 'Message expired',
		'116' => 'Invalid Unicode data',
		'120' => 'Invalid delivery time',
		'121' => 'Destination mobile number',
		'122' => 'Destination mobile opted out',
		'123' => 'Invalid Sender ID',
		'128' => 'Number delisted',
		'201' => 'Invalid batch ID',
		'202' => 'No batch template',
		'301' => 'No credit left',
		'302' => 'Max allowed credit'
	);

	return $codes{$errorCode};

}

###############################################################################

=item $id = $sms->sessionId();

Return the current session id

=cut

sub sessionid {

	my ($self) = @_;
	return $self->{'_session_id'};

}

###############################################################################

=item $resp = $sms->auth( user=>$user, password=>$password, api_id=>$api_id);

Send credentials to Clickatell to authenticate the session.

=over

=item user

Clickatell user id

=item password

Clickatell password

=item api_id

Regisered API ID as assigned by Clickatell

=back

The response will be:

=over

=item OK:

=item ERR: xxx

Error returned by the Clickatell API

=back

=cut

sub auth {

	my ($self, %params) = @_;
	
	#TODO: etter error checking of input parameters
	my $response = $self->{'_som'}->call(
		auth => SOAP::Data->name( 'user' => $params{'user'} ),
			SOAP::Data->name( 'password' => $params{'password'} ),
			SOAP::Data->name( 'api_id'   => $params{'api_id'} ),
	);

	## If the session was established successfully the response will be
	## "OK: <sesion_id>"
	my $result = $self->_checkResult($response);
	if ( $result =~ /OK:\s+(\S+)/ ) {
		$self->{'_session_id'} = $1;	# Save the session ID
		$self->{'_status'}     = 1;		# Mark session as active
		printf STDERR "Session ID %s has been assigned\n", $1 if $VERBOSE;
	} else {
		print STDERR "Error '$result' while establishing session\n" if $VERBOSE;
	}
		
	return $result;

}

###############################################################################

=item $resp = $sms->ping();

Send a ping to the service to keep the session alive.

The response will be:

=over

=item OK:

=item ERR: xxx

where xxx is a numeric error code

=back

=cut

sub ping {

	my ($self) = @_;
	printf STDERR "pinging on session '%s'... ", $self->{'_session_id'}
	  if $VERBOSE;

	my $response =
	  $self->{'_som'}->call(
		ping => SOAP::Data->name( 'session_id' => $self->{'_session_id'} ), );

	my $rc = _checkResult( $self, $response );
	printf STDERR "%s\n", $rc if $VERBOSE;
	return $rc;

}

###############################################################################

=item $resp = $sms->getbalance();

Query the number of credits available in the account.

=over

=item Credit: nn.nnn

Amount of outstanding credit balance for the account.

=item ERR: xxx

where xxx is a numeric error code

=back

=cut

sub getbalance {

	my ( $self, %data ) = @_;

	printf STDERR "getbalance %s... ", $self->{'_session_id'} if $VERBOSE;

	my $response =
	  $self->{'_som'}->call( getbalance =>
		  SOAP::Data->name( 'session_id' => $self->{'_session_id'} ), );

	my $rc = _checkResult( $self, $response );
	printf STDERR "%s\n", $rc if $VERBOSE;
	return $rc;

}

###############################################################################

=item $resp = $sms->routeCoverage( msisdn => $msisdn );

Chck the coverage of a network or number without sending a message.

where:

=over

=item msisdn

The network or number to be checked for coverage.

=back

The response will be:

=over

=item OK: followed by coverage information

Eg. OK: This prefix is currently supported. Messages sent to this prefix will be routed. Charge: 0.33

=item ERR: xxx

where xxx is a numeric error code

=back

=cut

sub routecoverage {

	my ( $self, %data ) = @_;

	printf STDERR "routeCoverage %s... ", $data{'msisdn'} if $VERBOSE;

	my $response = $self->{'_som'}->call(
		routeCoverage =>
		  SOAP::Data->name( 'session_id' => $self->{'_session_id'} ),
		SOAP::Data->name( 'msisdn'       => $data{'msisdn'} ),
	);

	my $rc = _checkResult( $self, $response );
	printf STDERR "%s\n", $rc if $VERBOSE;
	return $rc;

}

###############################################################################

=item $resp = $hSMS->querymsg( apiMsgId => $apiMsgId );

=item $resp = $hSMS->querymsg( cliMsgId => $cliMsgId );

=over

=item apiMsgId

API message id (apiMsgId) returned by the gateway after a message was sent.

=item cliMsgId

client message ID (cliMsgId) you used on submission of the message.

=back

the response will be:

=over

=item ID: followed by message status

eg. ID: 18e8221e5aa50cfad72376e08f40388a Status: 001;

Status codes are defined by the Clickatell API.

=item ERR:

where xxx is a numeric error code

=back

=cut

sub querymsg {

	my $idType = undef, my $matched = 0;

	my ( $self, %data ) = @_;

	foreach my $key ( 'apiMsgId', 'cliMsgId' ) {
		if ( exists $data{$key} && defined $data{$key} ) {
			$matched = 1;
			$idType  = $key;
		}
	}

	if ( !$matched ) {
		return "ERROR: Either 'apiMsgId' or 'cliMsgId' must be defined";
	}
	printf STDERR "querymsg %s=%s... ", $idType, $data{$idType} if $VERBOSE;

	my $response = $self->{'_som'}->call(
		querymsg => SOAP::Data->name( 'session_id' => $self->{'_session_id'} ),
		SOAP::Data->name( $idType => $data{$idType} ),
	);

	my $rc = _checkResult( $self, $response );
	printf STDERR "%s\n", $rc if $VERBOSE;
	return $rc;

}

###############################################################################

=item $resp = $sms->querymsg( apiMsgId => $apiMsgId );

Query the status of a message.

=over

=item apiMsgId

API message id (apiMsgId) returned by the gateway after a message was sent.

=back

the respones will be:

=over

=item apiMsgId: followed by message status

eg. apiMsgId: 18e8221e5aa50cfad72376e08f40388a charge: 0.33 status: 004; 

Status codes are defined by the Clickatell API.

=item ERR:

where xxx is a numeric error code

=back

=cut

sub getmsgcharge {

	my ( $self, %data ) = @_;

	if ( !exists $data{'apiMsgId'} || !defined $data{'apiMsgId'} ) {
		return "ERROR: Either 'apiMsgId' or 'cliMsgId' must be defined";
	}
	printf STDERR "querymsg %s=%s... ", 'apiMsgId', $data{'apiMsgId'}
	  if $VERBOSE;

	my $response = $self->{'_som'}->call(
		getmsgcharge =>
		  SOAP::Data->name( 'session_id' => $self->{'_session_id'} ),
		SOAP::Data->name( 'apiMsgId'     => $data{'apiMsgId'} ),
	);

	my $rc = _checkResult( $self, $response );
	printf STDERR "%s\n", $rc if $VERBOSE;
	return $rc;

}

###############################################################################

=item $resp = $hSMS->delmsg( apiMsgId => $apiMsgId );

=item $resp = $hSMS->delmsg( cliMsgId => $cliMsgId );

Delete a previously sent message.

=over

=item apiMsgId

API message id (apiMsgId) returned by the gateway after a message was sent.

=item cliMsgId

client message ID (cliMsgId) you used on submission of the message.

=back

the response will be:

=over

=item ID: followed by message status

eg. ID: 18e8221e5aa50cfad72376e08f40388a Status: 001;

Status codes are defined by the Clickatell API.

=item ERR:

where xxx is a numeric error code

=back

=cut

sub delmsg {

	my $idType = undef, my $matched = 0;

	my ( $self, %data ) = @_;

	foreach my $key ( 'apiMsgId', 'cliMsgId' ) {
		if ( exists $data{$key} && defined $data{$key} ) {
			$matched = 1;
			$idType  = $key;
		}
	}

	if ( !$matched ) {
		return "ERROR: Either 'apiMsgId' or 'cliMsgId' must be defined";
	}
	printf STDERR "delmsg %s=%s... ", $idType, $data{$idType} if $VERBOSE;

	my $response = $self->{'_som'}->call(
		delmsg => SOAP::Data->name( 'session_id' => $self->{'_session_id'} ),
		SOAP::Data->name( $idType => $data{$idType} ),
	);

	my $rc = _checkResult( $self, $response );
	printf STDERR "%s\n", $rc if $VERBOSE;
	return $rc;

}

###############################################################################

=item $resp = $hSMS->sendmsg(to => '19991234567', text => 'Hello there...');

=item $resp = $hSMS->sendmsg(to => @phoneNumbers, text => 'Hello there...');

Chck the coverage of a network or number without sending a message. If item_user
is supplied, then preexisting session authentication (if any) will be ignored
and the item_user, item_pasword and api_id values will be used to authenticate
this call. This allows you to send a message even if the existing session has
dropped for any reason.

=over

=item to (required)

A phone number or list of phone numbers to recieve the messsage

=item text (required)

The text of the message to be sent

=item api_id (not implemented yet)

=item user (not implemented yet)

=item password (not implemented yet)

=item from (not implemented yet)

=item concat (not implemented yet)

=item deliv_ack (not implemented yet)

=item callback (not implemented yet)

=item deliv_time (not implemented yet)

=item max_credits (not implemented yet)

=item req_feat (not implemented yet)

=item queue (not implemented yet)

=item escalate (not implemented yet)

=item mo (not implemented yet)

=item cliMsgId (not implemented yet)

=item unicode (not implemented yet)

=item msg_type (not implemented yet)

=item udh (not implemented yet)

=item data (not implemented yet)

=item validity (not implemented yet)

=back

The response will be:

=over

=item ID: followed by message id

eg. ID: 18e8221e5aa50cfad72376e08f40388a;

Status codes are defined by the Clickatell API.

=item ERR: xxx

where xxx is a numeric error code

e.g. ERR: 105, Invalid Destination Address;

=back

=cut

#TODO Add more than the basic parameters to sendmsg
sub sendmsg {

	my ( $authText, $authData, @dest );

	my ( $self, %data ) = @_;

	## Figure out what authentication scheme is to be used
	if (   defined $data{'item user'}
		&& exists $data{'item user'}
		&& length( $data{'item user'} ) > 0 )
	{
		$authText = 'as user ' . $data{'item user'};
		$authData = (
			SOAP::Data->name( 'api_id'        => $data{'api_id'} ),
			SOAP::Data->name( 'item user'     => $data{'item user'} ),
			SOAP::Data->name( 'item password' => $data{'item password'} )
		);
	} else {
		$authText = 'on session ' . $self->{'_session_id'};
		$authData = SOAP::Data->name( 'session_id' => $self->{'_session_id'} );
	}

	## Verify that the destination number(s) are in an array
	if ( ref( $data{'to'} ) eq 'ARRAY' ) {
		@dest = $data{'to'};
	} else {
		push( @dest, $data{'to'} );
	}

	printf STDERR "sendmsg to %s %s... ", $data{'to'}, $authText if $VERBOSE;

	my $response = $self->{'_som'}->call(
		sendmsg => $authData,

		#			SOAP::Data->name( 'session_id' => $self->{'_session_id'} ),
		#			SOAP::Data->name( 'api_id' => $data{'api_id'} ),
		#			SOAP::Data->name( 'item user' => $data{'item user'} ),
		#			SOAP::Data->name( 'item password' => $data{'item password'} ),
		SOAP::Data->name( 'to'          => @dest ),
		SOAP::Data->name( 'from'        => $data{'from'} ),
		SOAP::Data->name( 'text'        => $data{'text'} ),
		SOAP::Data->name( 'concat'      => $data{'concat'} ),
		SOAP::Data->name( 'deliv_ack'   => $data{'deliv_ack'} ),
		SOAP::Data->name( 'callback'    => $data{'callback'} ),
		SOAP::Data->name( 'deliv_time'  => $data{'deliv_time'} ),
		SOAP::Data->name( 'max_credits' => $data{'max_credits'} ),
		SOAP::Data->name( 'req_feat'    => $data{'req_feat'} ),
		SOAP::Data->name( 'queue'       => $data{'queue'} ),
		SOAP::Data->name( 'escalate'    => $data{'escalate'} ),
		SOAP::Data->name( 'mo'          => $data{'mo'} ),
		SOAP::Data->name( 'cliMsgId'    => $data{'cliMsgId'} ),
		SOAP::Data->name( 'unicode'     => $data{'unicode'} ),
		SOAP::Data->name( 'msg_type'    => $data{'msg_type'} ),
		SOAP::Data->name( 'udh'         => $data{'udh'} ),
		SOAP::Data->name( 'data'        => $data{'data'} ),
		SOAP::Data->name( 'validity'    => $data{'validity'} ),
	);

	my $rc = _checkResult( $self, $response );
	printf STDERR "%s\n", $rc if $VERBOSE;
	return $rc;

}

###############################################################################

=item $resp = $hSMS->si_push(to => '19991234567', si_text => 'Check this out', si_url = 'http://www.perl.org');

WAP Push Service Indication (SI) is a WAP address embedded within the header of 
a specially formatted SMS. This is displayed as an alert message to the user, 
and gives the user the option of connecting directly to a particular URL via 
the handsets WAP browser (if supported). This command enables you to send a WAP 
Push Service Indication.

=over

=item to (required)

A phone number or list of phone numbers to recieve the messsage

=item si_id (required)

Unique ID for each message

=item si_url (required)

The URL used to access the service

=item si_text (required)

The text of the message to be sent

=item si_created (not implemented yet)

=item si_expires (not implemented yet)

=item si_action (not implemented yet)

=item from (not implemented yet)

=item concat (not implemented yet)

=item deliv_ack (not implemented yet)

=item callback (not implemented yet)

=item deliv_time (not implemented yet)

=item max_credits (not implemented yet)

=item req_feat (not implemented yet)

=item queue (not implemented yet)

=item escalate (not implemented yet)

=item mo (not implemented yet)

=item cliMsgId (not implemented yet)

=item validity (not implemented yet)

=back

The response will be:

=over

=item ID: xxx TO: xxx

eg. ID: ID: 18e8221e5aa50cfad72376e08f40388a TO: 99991234567;

Status codes are defined by the Clickatell API.

=item ERR: xxx

where xxx is a numeric error code

e.g. ERR: 105, Invalid Destination Address;

=back

=cut

#TODO Add more than the basic parameters
#TODO Allow user/password/api_id authentication
sub si_push {

	my ( $authText, $authData, @dest );

	my ( $self, %data ) = @_;

	## Verify that the destination number(s) are in an array
	if ( ref( $data{'to'} ) eq 'ARRAY' ) {
		@dest = $data{'to'};
	} else {
		push( @dest, $data{'to'} );
	}

	printf STDERR "sendmsg to %s %s... ", $data{'to'}, $authText if $VERBOSE;

	my $response = $self->{'_som'}->call(
		sendmsg => 		
			SOAP::Data->name( 'session_id' => $self->{'_session_id'} ),
			SOAP::Data->name( 'to'          => @dest ),
			SOAP::Data->name( 'from'        => $data{'from'} ),
			SOAP::Data->name( 'si_id'       => $data{'si_id'} ),
			SOAP::Data->name( 'si_text'     => $data{'si_text'} ),
			SOAP::Data->name( 'si_url'      => $data{'si_url'} ),
#			SOAP::Data->name( 'si_created'  => $data{'si_created'} ),
#			SOAP::Data->name( 'si_expires'  => $data{'si_expires'} ),
#			SOAP::Data->name( 'si_action'   => $data{'si_action'} ),			
#			SOAP::Data->name( 'concat'      => $data{'concat'} ),
#			SOAP::Data->name( 'deliv_ack'   => $data{'deliv_ack'} ),
#			SOAP::Data->name( 'callback'    => $data{'callback'} ),
#			SOAP::Data->name( 'deliv_time'  => $data{'deliv_time'} ),
#			SOAP::Data->name( 'max_credits' => $data{'max_credits'} ),
#			SOAP::Data->name( 'req_feat'    => $data{'req_feat'} ),
#			SOAP::Data->name( 'queue'       => $data{'queue'} ),
#			SOAP::Data->name( 'escalate'    => $data{'escalate'} ),
#			SOAP::Data->name( 'mo'          => $data{'mo'} ),
#			SOAP::Data->name( 'cliMsgId'    => $data{'cliMsgId'} ),
#			SOAP::Data->name( 'validity'    => $data{'validity'} ),
	);

	my $rc = _checkResult( $self, $response );
	printf STDERR "%s\n", $rc if $VERBOSE;
	return $rc;

}

###############################################################################
## End of package
###############################################################################

1;

__END__

=back 

=head1 SEE ALSO

SOAP::Lite, Clickatell SOAP API Specification V 1.1.8

=head1 AUTHOR

Peter Farr <peter.farr@lpi-solutions.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Peter Farr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut
