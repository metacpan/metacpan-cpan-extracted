# Mobile::Messaging::ParlayX.pm version 0.0.3
#
# Copyright (c) 2006 Thanos Chatziathanassioy <tchatzi@arx.net>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mobile::Messaging::ParlayX;
local $^W;
require 'Exporter.pm';
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = (Exporter);
@EXPORT = qw();   #&new);
@EXPORT_OK = qw(@error_str);

$Mobile::Messaging::ParlayX::VERSION='0.0.3';
$Mobile::Messaging::ParlayX::ver=$Mobile::Messaging::ParlayX::VERSION;

use strict 'vars';
use Carp();
use LWP::UserAgent();
use HTTP::Request();
use XML::LibXML();

@Mobile::Messaging::ParlayX::Errors = ( 
										
										);

=head1 NAME

Mobile::Messaging::ParlayX - Interface to ParlayX OSA.

Version 0.0.3

=head1 SYNOPSIS

 use Mobile::Messaging::ParlayX;

=head1 DESCRIPTION

C<Mobile::Messaging::ParlayX> is an interface to ParlayX web service by Sony Ericsson for SMS and MMS messaging,
among other things.
This being a Web Service L<SOAP::Lite> would probably be better suited to the task, but I decided to stick 
with C<LWP::UserAgent>, C<HTTP::Request> and C<XML::LibXML> until things in C<SOAP::Lite> stabilize (it is currently
under rewrite as far as I know) and I have more time (not that this will happen anytime soon).
Besides, I cannot fully grasp ParlayX just yet, thanks to inadequate documentation and JAVA only code 
samples for it.
Anyway, you need L<LWP::UserAgent> , L<HTTP::Request> and L<XML::LibXML> for this module to work.
Most are in the standard distribution already, but any of them are available at your local CPAN mirror.

I tried not to stray too far off the ``native'' JAVA names of method and properties, but chances are some 
differences exist.

=head1 new Mobile::Messaging::ParlayX

 new Mobile::Messaging::ParlayX

=head2 Parameters/Properties

=over 4

=item username

C<>=> Your mobile operator should provide you with this, along with

=item password

C<>=> for your authentication against his gateway.

=item nonce

C<>=> This is also supposed to be part of the authentication process, though I`m not quite sure what it does...
Note that both password and nonce seem to be some kind of Base64 encoded digests, though I`m not quite sure what they are. 
If you figure it out, I`ll be happy to include them here.

=item host

C<>=> Your operators` mobile gateway; the one your SOAP request will end up in. 

=item senderName

C<>=> Technically, the originator of the SMS. Specs say it can be alphanumeric up to 11 chars in length,
though your operator may or may not allow you to set it.

=item receiptRequest

C<>=> You can ask for a delivery report for each SMS message, though the details of this are unclear to me,
since my operator does not (for the time being) support this. ``receiptRequest'' should be a hash reference
with ``endpoint'', ``correlator'' and ``interfaceName'' as the keys.
In theory, endpoint should be a URI of your own, where the operator will POST a SOAP of the results of the
SMS. Correlator is supposed to be a unique ID for this message, and your guess is as good as mine what
``interfaceName'' stands for.
How this works and how bad, I do not know, since if I put receiptRequest in my SOAP request, my operator 
will drop the message altogether. 
You can still try and send me a patch/recommendation though.

=item ChargingInformation

C<>=> This is supposed to carry MT (Mobile Terminated) charging info in it and seems to work better than
receiptRequest above, but I cannot confirm this yet.
It is also a hash reference with ``description'' (probably will appear on the users` bill as such), 
``currency'' and ``amount'' (which are fairly self-explanatory, although amount should be decimal ie not a 
float) and ``code'' (which I haven`t the faintest idea what it does). 
if you provide at least the first 3, the module will put the relavant item in the SOAP request, though
again I cannot guarantee that it`ll work as expected.
UPDATE: Either amount and currency or just plain code will work. Code is supposed to contain what TIM
refers to as VASID and VASPID, which in itself is enough for an MT message.

=back

=cut

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	return $self->initialize(@_);
}

sub initialize {
	my $self = shift;
	
	if (@_ != 0) {
		if (ref $_[0] eq 'HASH') {
			my $hash=$_[0];
			foreach (keys %$hash) {
				$self->{lc $_}=$hash->{$_};
			}
		}
	}
	
	$self->{'die_on_error'} ||= 0;
	$self->{'DEBUG'} ||= 0;
	
	$self->{'ua'} = new LWP::UserAgent;
	$self->{'ua'}->agent("Mobile::Messaging::ParlayX/0.0.3");
	
	$self->{'parser'} = XML::LibXML->new();
	
	return $self;
}

=pod

=head2 Methods

=over 4

=item sendSMS

C<>=> Pretty much finished. It would be highly unusable without named arguments, so call it like so:

	$self->sendSMS( { 
		username => 'Your ParlayX Username',
		host => 'ParlayX SMS Gateway',
		password => 'Password',
		nonce => 'No Idea What This Does',
		senderName => 'Where The SMS will Seem to Come From',
		message => 'The actual sms message',
		addresses => 'Recipient(s)',
		receiptRequest => { 
			endpoint => 'URI where the reciept will be sent',
			interfaceName => 'Never used that one and dont quite know what it is',
			correlator => 'Unique ID of the receiver'
		}
		ChargingInformation => {
			description => 'Arbitrary string describing the reason for the MT charge',
			currency => 'Should be self-explanatory, but my operator does not use it',
			amount => 'Ditto, because these are inside argument code',
			code => 'Instead of amount and currency, you have these pre-packaged in code'
			}
	} );

Obviously username, host, message and addresses are mandatory for anything to work at all, the rest
can be filled in according to your requirements. Your operator should give you a pretty good idea
what`s neccessary and what is not.
Returns two scalars, the first indicating success (1) or not (0) while the second will give you the
unique id of the message (for future delivery report queries) in case of success. In case of failure
it will hopefully contain the error string returned by ParlayX Gateway.
The module will happily croak() if LWP::UserAgent cannot establish communication with ParlayX Gateway.
Ah, message and addresses can be array references, to send different messages to different recipients
or the same message to multiple recipients, or even different messages to the same recipient. Mix 
those as you see fit.

=back

=cut

sub sendSMS {
	my $self = shift;
	
	$self->{'DEBUG'} and warn "Entering sendSMS\n";
	
	my ($username, $password, $nonce, $host, $senderName, $message, $receiptRequest, $ChargingInformation, $addresses);
	if (ref $_[0] eq 'HASH') {
		$username   = $_[0]->{'username'}   || $self->{'username'}   || Carp::croak("Cant sendSMS without username\n");
		$host       = $_[0]->{'host'}       || $self->{'host'}       || Carp::croak("Cant sendSMS without ParlayX host definition\n");
		$password   = $_[0]->{'password'}   || $self->{'password'}   || '';
		$nonce      = $_[0]->{'nonce'}      || $self->{'nonce'}      || '';
		$senderName = $_[0]->{'senderName'} || $self->{'senderName'} || '';
		$message    = $_[0]->{'message'}    || $self->{'message'}    || '';
		$addresses  = $_[0]->{'addresses'}  || $self->{'addresses'}  || '';
		
		#special handling of $receiptRequest & $ChargingInformation
		$receiptRequest      = $_[0]->{'receiptRequest'}      || $self->{'receiptRequest'}      || '';
		$ChargingInformation = $_[0]->{'ChargingInformation'} || $self->{'ChargingInformation'} || '';
		
		if ($receiptRequest && ref($receiptRequest) ne 'HASH') {
			Carp::croak("\$receiptRequest is not a hash reference\n");
		}
		
		if ($ChargingInformation && ref($ChargingInformation) ne 'HASH') {
			Carp::croak("\$ChargingInformation is not a hash reference\n");
		}
		
		if (!$addresses) {
			Carp::croak("No recipients for SMS!\n");
		}
	}
	
	$self->{'DEBUG'} and warn "Constructing SOAP request..\n";
	
	#construct the SOAP request..header first.
	my $soap = $self->soap_send_body($username,$password,$nonce,$addresses,$senderName,$message,$receiptRequest,$ChargingInformation);
	
	$self->parse_xml(\$soap);
	
	$self->{'DEBUG'} and warn "SOAP request passed XML validation, sending HTTP Request\n";
	
	my ($soapaction,$lookfor) = ('http://www.csapi.org/wsdl/parlayx/sms/send/v2_1/local','result');
	return $self->doHTTP($host,\$soap,$soapaction,$lookfor);
}

=pod

=over 4

=item getSmsDeliveryStatus

C<>=> Pretty much finished too. It would be highly unusable without named arguments, so call it like so:

	$self->getSmsDeliveryStatus( { 
		username => 'Your ParlayX Username',
		host => 'ParlayX SMS Gateway',
		password => 'Password',
		nonce => 'No Idea What This Does',
		messageid => 'A message unique ID, obtained from sendSMS() above',
	} );

Needs username, host and messageid for anything to work at all, the rest
can be filled in according to your requirements. Your operator should give you a pretty good idea
what`s neccessary and what is not.
Returns a scalar indicating success (1) or not (0) and a hash reference (if you only asked 
for a single message ID) containing deliveryStatus and recipients` address (addresses).
if you used an array reference to ask for multiple message IDs, the 2nd returning value will be
an array reference with hashes like the one above inside it (should work, but could not be tested
in time).

=back

=cut

sub getSmsDeliveryStatus {
	my $self = shift;
	
	$self->{'DEBUG'} and warn "Entering getSmsDeliveryStatus()\n";
	
	my ($username, $password, $nonce, $host, $messageid, $addresses);
	if (ref $_[0] eq 'HASH') {
		$username   = $_[0]->{'username'}   || $self->{'username'}   || Carp::croak("Cant getSmsDeliveryStatus without username\n");
		$host       = $_[0]->{'host'}       || $self->{'host'}       || Carp::croak("Cant getSmsDeliveryStatus without ParlayX host definition\n");
		$password   = $_[0]->{'password'}   || $self->{'password'}   || '';
		$nonce      = $_[0]->{'nonce'}      || $self->{'nonce'}      || '';
		$messageid  = $_[0]->{'messageid'}  || $self->{'messageid'}  || '';
		$addresses  = $_[0]->{'addresses'}  || $self->{'addresses'}  || '';
		
		if (!$messageid) {
			Carp::croak("Need messageid for delivery status!\n");
		}
	}
	
	$self->{'DEBUG'} and warn "Constructing SOAP request..\n";
	
	my $soap = $self->soap_deliv_body($username,$password,$nonce,$messageid);
	
	$self->parse_xml(\$soap);
	
	$self->{'DEBUG'} and warn "SOAP request passed XML validation, sending HTTP Request\n";
	
	my ($soapaction,$lookfor) = (
								 '',{ deliveryStatus => '',
									  address		 => '' }
								);
	my ($success,$result) = $self->doHTTP($host,\$soap,$soapaction,$lookfor);
		
	return ($success,$result);
}

=pod

=over 4

=item ReceiveSms

C<>=> Works quite well for me YMMV. 

	$self->ReceiveSms( { 
		username => 'Your ParlayX Username',
		host => 'ParlayX SMS Gateway',
		password => 'Password',
		nonce => 'No Idea What This Does',
		registrationIdentifier => 'Never seen this used, so dont know what it does - username should be enough to identify you',
	} );

This is the polling interface for receiving SMS from ParlayX. Using it will result in ParlayX
``de-spooling'' awaiting SMSs for you.
Obviously needs a username to work and may need registrationIdentifier, the rest
can be filled in according to your requirements. Your operator should give you a pretty good idea
what`s neccessary and what is not.
Returns a scalar indicating success (1) or not (0) and a hash reference (if only a single SMS was waiting 
in line) containing message, senderAddress and the number the SMS was sent to (smsServiceActivationNumber).
if multiple messages are waiting, the 2nd returning value will be
an array reference with hashes like the one above inside it.

=back

=cut

sub ReceiveSms {
	my $self = shift;
	
	$self->{'DEBUG'} and warn "Entering ReceiveSms()\n";
	
	my ($username, $password, $nonce, $host, $registrationIdentifier);
	if (ref $_[0] eq 'HASH') {
		$username   = $_[0]->{'username'}   || $self->{'username'}   || Carp::croak("Cant getSmsDeliveryStatus without username\n");
		$host       = $_[0]->{'host'}       || $self->{'host'}       || Carp::croak("Cant getSmsDeliveryStatus without ParlayX host definition\n");
		$password   = $_[0]->{'password'}   || $self->{'password'}   || '';
		$nonce      = $_[0]->{'nonce'}      || $self->{'nonce'}      || '';
		
		$registrationIdentifier = $_[0]->{'registrationIdentifier'} || $self->{'registrationIdentifier'} || '';
	}
	
	$self->{'DEBUG'} and warn "Constructing SOAP request..\n";
	
	my $soap = $self->soap_receivesms_body($username,$password,$nonce,$registrationIdentifier);
	
	$self->parse_xml(\$soap);
	
	$self->{'DEBUG'} and warn "SOAP request passed XML validation, sending HTTP Request\n";
	
	my ($soapaction,$lookfor) = (
									'', {
											message						=> '',
											senderAddress				=> '',
											smsServiceActivationNumber	=> ''
										}
								);
	my ($success,$result) = $self->doHTTP($host,\$soap,$soapaction,$lookfor);
		
	return ($success,$result);
}

=pod

=over 4

=item ReceiveAutoSms

C<>=> 
$self->ReceiveAutoSms($incoming_soap_post);

This is the other (lets call on-demand) interface for receiving SMS from ParlayX.
You need to register yourself with the gateway (see C<startSmsNotification()> and C<stopSmsNotification()> below)
and then, whenever you have an incoming SMS, the gateway will POST any SMS to the URI you specified there.
Returns a hash reference containing message, senderAddress and the number the SMS was sent to (smsServiceActivationNumber).
An example, written in mod_perl/Apache::ASP, script accepting SMS follows.

	<%
		use strict;
		use Mobile::Messaging::ParlayX;
		my $incoming = $Request->BinaryRead();
		$incoming =~ s|<message>|<result>|s;
		$incoming =~ s|(smsServiceActivationNumber>.*?)</message>|$1</result>|s;
		my $ret = $sms->ReceiveAutoSms(\$incoming);
	%>>

In the example above, now $ret->{'message'} contains the SMS, $ret->{'smsServiceActivationNumber'} contains the number
the SMS was sent to (but prefixed with ``tel:'' so you might want to remove this before replying) and $ret->{'senderAddress'}
contains the number of the person who sent the SMS (which can be used as is in the reply).
Due to (our operator`s only ?) ParlayX being slightly liberal (for lack of a better word) it uses <message>, while it
meant <result>. The regex is there to make the message compatible with ReceiveSms() parsing above.
Also note the use of ``\$incoming'': In general, I try to avoid copying large strings back and forth and most of the module
will happily accept a scalar or a reference when either would apply. So you could use 
``my $ret = $sms->ReceiveAutoSms($incoming);'' instead if you feel more comfortable with it.
Personally, I designed it so I could use ``my $ret = $sms->ReceiveAutoSms(\$Request->BinaryRead());'' and I would too, 
if it were not for the funky <message> instead of <result> stuff.

=back

=cut

sub ReceiveAutoSms {
	my $self = shift;
	
	my $soap = shift;
	
	if (ref($soap)) {
		return $self->parse_xml($soap, {
										message						=> '',
										senderAddress				=> '',
										smsServiceActivationNumber	=> ''
										}
								);
	}
	else {
		return $self->parse_xml(\$soap, {
										message						=> '',
										senderAddress				=> '',
										smsServiceActivationNumber	=> ''
										}
								);
	}
}
										
=pod

=over 4

=item stopSmsNotification

C<>=> 

	$self->stopSmsNotification( { 
		username => 'Your ParlayX Username',
		host => 'ParlayX SMS Gateway',
		password => 'Password',
		nonce => 'No Idea What This Does',
		correlator => 'Unique Identifier for you (assigned when you did startSmsNotification()'
	} );

if you previously registered yourself with ParlayX with C<startSmsNotification()> and you do not want to automatically
recieve SMS from now on, use this. It tells ParlayX to stop sending you SMS to the URI you specified.
You`ll probably never have to use this, but it is included for the sake of completeness.
I have no idea if it works without a correlator (mine doesn`t), but if you implementation is different, feel free to
fix this.

=back

=cut
									
sub stopSmsNotification {
	my $self = shift;
	
	$self->{'DEBUG'} and warn "Entering stopSmsNotification()\n";
	
	my ($username, $password, $nonce, $host, $correlator);
	if (ref $_[0] eq 'HASH') {
		$username   = $_[0]->{'username'}   || $self->{'username'}   || Carp::croak("Cant getSmsDeliveryStatus without username\n");
		$host       = $_[0]->{'host'}       || $self->{'host'}       || Carp::croak("Cant getSmsDeliveryStatus without ParlayX host definition\n");
		$password   = $_[0]->{'password'}   || $self->{'password'}   || '';
		$nonce      = $_[0]->{'nonce'}      || $self->{'nonce'}      || '';
		
		$correlator    = $_[0]->{'correlator'}    || $self->{'correlator'}    || '';
		
		if (!$correlator) {
			Carp::croak("Need correlator for stopSmsNotification!\n");
		}
	}
	
	$self->{'DEBUG'} and warn "Constructing SOAP request..\n";
	
	my $soap = $self->soap_stopsms_body($username,$password,$nonce,$correlator);
	
	$self->parse_xml(\$soap);
	
	$self->{'DEBUG'} and warn "SOAP request passed XML validation, sending HTTP Request\n";
	
	my ($soapaction,$lookfor) = ('', 'Body');
	my ($success,$result) = $self->doHTTP($host,\$soap,$soapaction,$lookfor);
		
	return ($success,$result);
}

=pod

=over 4

=item startSmsNotification

C<>=> 

	$self->startSmsNotification( { 
		username => 'Your ParlayX Username',
		host => 'ParlayX SMS Gateway',
		password => 'Password',
		nonce => 'No Idea What This Does',
		endpoint => 'YOUR URI that ParlayX will send SMS to',
		correlator => 'A unique ID for you (more on this later)',
		interfaceName => 'No idea..always empty as far as I know'
	} );

To register yourself with ParlayX you need to use this. After you do, all SMS to your number will be sent to the
URI you specify in ``endpoint''.
if you do not specify a correlator, L<time()|perlfunc/time> will be used.
Returns 3 scalars, the first indicating success (1) or failure (0), the second your designated correlator (keep this
somewhere safe) and the third will normall be empty, except for error cases, where it will contain extended error
information.
Probably one-off use for it...

=back

=cut

sub startSmsNotification {
	my $self = shift;
	
	$self->{'DEBUG'} and warn "Entering startSmsNotification()\n";
	
	my ($username, $password, $nonce, $host, $endpoint, $correlator, $interfaceName, $smsServiceActivationNumber, $criteria);
	if (ref $_[0] eq 'HASH') {
		$username   = $_[0]->{'username'}   || $self->{'username'}   || Carp::croak("Cant getSmsDeliveryStatus without username\n");
		$host       = $_[0]->{'host'}       || $self->{'host'}       || Carp::croak("Cant getSmsDeliveryStatus without ParlayX host definition\n");
		$password   = $_[0]->{'password'}   || $self->{'password'}   || '';
		$nonce      = $_[0]->{'nonce'}      || $self->{'nonce'}      || '';
		
		$endpoint      = $_[0]->{'endpoint'}      || $self->{'endpoint'}      || '';
		$correlator    = $_[0]->{'correlator'}    || $self->{'correlator'}    || '';
		$interfaceName = $_[0]->{'interfaceName'} || $self->{'interfaceName'} || '';
		
		$smsServiceActivationNumber = $_[0]->{'smsServiceActivationNumber'} || $self->{'smsServiceActivationNumber'} || '';
		$criteria                   = $_[0]->{'criteria'}                   || $self->{'criteria'}                   || '';
		
		if (!$endpoint) {
			Carp::croak("Need endpoint for startSmsNotification!\n");
		}
		elsif (!$smsServiceActivationNumber) {
			Carp::croak("Need smsServiceActivationNumber for startSmsNotification!\n");
		}
		
		if (!$correlator) {
			$correlator = time();
		}
	}
	
	$self->{'DEBUG'} and warn "Constructing SOAP request..\n";
	
	my $soap = $self->soap_startsms_body($username,$password,$nonce,$endpoint,$correlator,$interfaceName,$smsServiceActivationNumber,$criteria);
	
	$self->parse_xml(\$soap);
	
	$self->{'DEBUG'} and warn "SOAP request passed XML validation, sending HTTP Request\n";
	
	my ($soapaction,$lookfor) = ('', 'Body');
	my ($success,$result) = $self->doHTTP($host,\$soap,$soapaction,$lookfor);
		
	return ($success,$correlator,$result);
}

=pod

=head2 Esoterics

=over 4

=item Before we do this, know that all this is subject (rather mandatory I think) to change.

=item soap_header

=item soap_footer

=item parse_xml

=item doHTTP

=item soap_startsms_body

=item soap_stopsms_body

=item soap_deliv_body

=item soap_send_body

=item soap_receivesms_body

=item receipt_request

=item charging_info

C<>=> In very particular order, the top 4 things are not very likely to change anytime soon, 
unless L<SOAP::Lite> transforms into something usable by a poor smuck like me soon.
About the rest, I do not know, especially charging_info and receipt_request are only written
based on (shoddy) documentation and have never been used in real life.

=back

=cut

sub soap_startsms_body {
	my $self = shift;
	
	my ($username,$password,$nonce,$endpoint,$correlator,$interfaceName,$smsServiceActivationNumber,$criteria) = @_;
	
	my $soap = $self->soap_header($username,$password,$nonce);
	
	$soap .= qq[<ns2:startSmsNotification xmlns:ns2="http://www.csapi.org/schema/parlayx/sms/notification_manager/v2_2/local" xmlns:ns3="http://www.csapi.org/schema/parlayx/common/v2_1">
					<ns2:reference>
						<endpoint>$endpoint</endpoint>
						<interfaceName>$interfaceName</interfaceName>
						<correlator>$correlator</correlator>
					</ns2:reference>
					<ns2:smsServiceActivationNumber>$smsServiceActivationNumber</ns2:smsServiceActivationNumber>
					<ns2:criteria>$criteria</ns2:criteria>
				</ns2:startSmsNotification>];
	
	$soap .= $self->soap_footer();
	
	return $soap;
}

sub soap_stopsms_body {
	my $self = shift;
	
	my ($username,$password,$nonce,$correlator) = @_;
	
	my $soap = $self->soap_header($username,$password,$nonce);
	
	$soap .= qq[<ns2:stopSmsNotification xmlns:ns2="http://www.csapi.org/schema/parlayx/sms/notification_manager/v2_2/local" xmlns:ns3="http://www.csapi.org/schema/parlayx/common/v2_1">
					<ns2:correlator>$correlator</ns2:correlator>
				</ns2:stopSmsNotification>];
	
	$soap .= $self->soap_footer();
	
	return $soap;
}

sub soap_deliv_body {
	my $self = shift;
	
	my ($username,$password,$nonce,$messageid) = @_;
	
	my $soap = $self->soap_header($username,$password,$nonce);
	
	if (ref($messageid) eq 'ARRAY') {
		foreach (@{$messageid}) {
			$soap .= qq[<ns2:getSmsDeliveryStatus xmlns:ns2="http://www.csapi.org/schema/parlayx/sms/send/v2_1/local" xmlns:ns3="http://www.csapi.org/schema/parlayx/common/v2_1">
							<ns2:requestIdentifier>$_</ns2:requestIdentifier>
						</ns2:getSmsDeliveryStatus>];
		}
	}
	elsif ($messageid) {
		$soap .= qq[<ns2:getSmsDeliveryStatus xmlns:ns2="http://www.csapi.org/schema/parlayx/sms/send/v2_1/local" xmlns:ns3="http://www.csapi.org/schema/parlayx/common/v2_1">
						<ns2:requestIdentifier>$messageid</ns2:requestIdentifier>
					</ns2:getSmsDeliveryStatus>];
	}
					
	$soap .= $self->soap_footer();
	
	return $soap;
}

sub soap_send_body {
	my $self = shift;
	my ($username,$password,$nonce,$addresses,$senderName,$message,$receiptRequest,$ChargingInformation) = @_;
	
	my $soap = $self->soap_header($username,$password,$nonce);
	
	if (ref($message) eq 'ARRAY') {
		#different messages for (possibly) different recipients
		for (my $i=0; $i < scalar(@{$message}); $i++) {
						
			$soap .= qq[<ns2:sendSms xmlns:ns2="http://www.csapi.org/schema/parlayx/sms/send/v2_1/local" xmlns:ns3="http://www.csapi.org/schema/parlayx/common/v2_1">];
			
			if (ref($addresses) eq 'ARRAY' && $addresses->[$i]) {
				$soap .= qq[<ns2:addresses>$addresses->[$i]</ns2:addresses>];
			}
			else {
				$soap .= qq[<ns2:addresses>$addresses</ns2:addresses>];
			}
			
			if (ref($senderName) eq 'ARRAY' && $senderName->[$i]) {
				$soap .= qq[<ns2:senderName>$senderName->[$i]</ns2:senderName>];
			}
			else {
				$soap .= qq[<ns2:senderName>$senderName</ns2:senderName>];
			}
			
			$soap .= qq[<ns2:message>$message->[$i]</ns2:message>];
			
			if (ref($receiptRequest) eq 'ARRAY' && ref($receiptRequest->[$i]) eq 'HASH') {
				$soap .= $self->receipt_request($receiptRequest->[$i]);
			}
			elsif ($receiptRequest) {
				$soap .= $self->receipt_request($receiptRequest);
			}
			
			if (ref($ChargingInformation) eq 'ARRAY' && ref($ChargingInformation->[$i]) eq 'HASH') {
				$soap .= $self->charging_info($ChargingInformation->[$i]);
			}
			elsif ($ChargingInformation) {
				$soap .= $self->charging_info($ChargingInformation);
			}
			
			$soap .= qq[</ns2:sendSms>];
		}
	}
	elsif (ref($addresses) eq 'ARRAY') {
		#same message to different recipients
		foreach (@{$addresses}) {
			$soap .= qq[<ns2:sendSms xmlns:ns2="http://www.csapi.org/schema/parlayx/sms/send/v2_1/local" xmlns:ns3="http://www.csapi.org/schema/parlayx/common/v2_1">
							<ns2:addresses>$_</ns2:addresses>
							<ns2:message>$message</ns2:message>];
			
			if ($senderName) {
				$soap .= qq[<ns2:senderName>$senderName</ns2:senderName>];
			}
			
			if ($receiptRequest) {
				$soap .= $self->receipt_request($receiptRequest);
			}
			
			if ($ChargingInformation) {
				$soap .= $self->charging_info($ChargingInformation);
			}
			
			$soap .= qq[</ns2:sendSms>];
		}
	}
	else {
		#one message, one recipient
		$soap .= qq[<ns2:sendSms xmlns:ns2="http://www.csapi.org/schema/parlayx/sms/send/v2_1/local" xmlns:ns3="http://www.csapi.org/schema/parlayx/common/v2_1">
						<ns2:addresses>$addresses</ns2:addresses>
						<ns2:message>$message</ns2:message>];
	
		if ($senderName) {
			$soap .= qq[<ns2:senderName>$senderName</ns2:senderName>];
		}
			
		if ($receiptRequest) {
			$soap .= $self->receipt_request($receiptRequest);
		}
		
		if ($ChargingInformation) {
			$soap .= $self->charging_info($ChargingInformation);
		}
		
		$soap .= qq[</ns2:sendSms>];
	}
	
	$soap .= $self->soap_footer();
	
	return $soap;
}

sub soap_header {
	my $self = shift;
	my $username = shift || $self->{'username'};
	my $password = shift || $self->{'password'} || '';
	my $nonce    = shift || $self->{'nonce'}    || '';
	
	if ($password) {
		$password = q[<wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">].$password.q[</wsse:Password>];
		
		#only if password, can nonce make sense or not ?
		if ($nonce) {
			$nonce = q[<wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">].$nonce.q[</wsse:Nonce>];
		}
	}
	
	return qq[<?xml version="1.0" ?>
		<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
			<SOAP-ENV:Header>
				<wsse:Security SOAP-ENV:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
					<wsse:UsernameToken wsu:Id="XWSSGID-11435375577461001212174" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
						<wsse:Username>]
					.$username
					.qq[</wsse:Username>]
					.$password
					.$nonce
					.qq[	
					</wsse:UsernameToken>
				</wsse:Security>
			</SOAP-ENV:Header>
			<SOAP-ENV:Body>];
}

sub soap_footer {
	my $self = shift;
	
	return qq[</SOAP-ENV:Body>
		</SOAP-ENV:Envelope>];
}

sub receipt_request {
	my $self = shift;
	
	my $rr = shift;
	
	if (ref($rr) ne 'HASH') {
		Carp::croak("Cant do receipt request without endpoint, interfaceName or correlator (receiptRequest is not a HASH reference\n");
	}
	
	if ($rr->{'endpoint'}) {
		$rr->{'endpoint'} = qq[<endpoint>$rr->{'endpoint'}</endpoint>];
	}
	if ($rr->{'correlator'}) {
		$rr->{'correlator'} = qq[<correlator>$rr->{'correlator'}</correlator>];
	}
	if ($rr->{'interfaceName'}) {
		$rr->{'interfaceName'} = qq[<interfaceName>$rr->{'interfaceName'}</interfaceName>];
	}
	
	if ($rr->{'interfaceName'} || $rr->{'correlator'} || $rr->{'endpoint'}) {
		return qq[<ns2:receiptRequest> $rr->{'endpoint'} $rr->{'interfaceName'} $rr->{'correlator'} </ns2:receiptRequest>];
	}
	else {
		return '';
	}
}

sub soap_receivesms_body {
	my $self = shift;
	my ($username,$password,$nonce,$registrationIdentifier) = @_;
	
	my $soap = $self->soap_header($username,$password,$nonce);
	
	$soap .= qq[<ns2:getReceivedSms xmlns:ns2="http://www.csapi.org/schema/parlayx/sms/receive/v2_1/local" xmlns:ns3="http://www.csapi.org/schema/parlayx/common/v2_1">];
	
	if ($registrationIdentifier) {
		$soap .= qq[<ns2:registrationIdentifier>$registrationIdentifier</ns2:registrationIdentifier>];
	}
	
	$soap .= qq[</ns2:getReceivedSms>];
	
	$soap .= $self->soap_footer();
}

sub charging_info {
	my $self = shift;
	
	my $ci = shift;
	
	if (ref($ci) ne 'HASH') {
		Carp::croak("Cant do charging information without description, currency, amount or code (ChargingInformation is not a HASH reference\n");
	}
	
	if ($ci->{'description'}) {
		$ci->{'description'} = qq[<description>$ci->{'description'}</description>];
	}
	if ($ci->{'currency'}) {
		$ci->{'currency'} = qq[<currency>$ci->{'currency'}</currency>];
	}
	if ($ci->{'amount'}) {
		$ci->{'amount'} = qq[<amount>$ci->{'amount'}</amount>];
	}
	if ($ci->{'code'}) {
		$ci->{'code'} = qq[<code>$ci->{'code'}</code>];
	}
	
	if ( ($ci->{'currency'} && $ci->{'amount'}) || $ci->{'code'} ) {
		return qq[<ns2:charging> $ci->{'currency'} $ci->{'amount'} $ci->{'description'} $ci->{'code'} </ns2:charging>];
	}
	else {
		return '';
	}
}

sub parse_xml {
	my $self = shift;
	
	my $soap = shift;
		
	my $returns = shift || '';
	
	my $doc;
	
	eval {
		if (ref($soap)) {
			$self->{'DEBUG'} and warn "SOAP document:\n". ("-" x 80) . "\n" . $$soap . "\n" .("-" x 80) ."\n";
			#might be a reference
			$doc = $self->{'parser'}->parse_string($$soap);
		}
		else {
			$self->{'DEBUG'} and warn "SOAP document:\n". ("-" x 80) . "\n$soap" . "\n" . ("-" x 80) ."\n";
			$doc = $self->{'parser'}->parse_string($soap);
		}
	};
	
	if ($@) {
		if (ref($soap)) {
			Carp::croak("SOAP document:\n\n$$soap\n\n is not valid XML\n");
		}
		else {
			Carp::croak("SOAP document:\n\n$soap\n\n is not valid XML\n");
		}
	}
	
	if (!$returns) {
		return 1;
	}
	else {
		my $ret = '';
		
		if (ref($returns) eq 'HASH') {
			my $count = 0; #one or more ``results'' ?
			#$ret will be an array of hashes if more than one
			$ret = [];
			foreach my $res ($doc->getElementsByTagName('result')) {
				if ($count) {
					push @{$ret},$returns;
				}
				foreach (keys(%{$returns})) {
					$returns->{$_} = $res->findvalue($_);
				}
				$count++;
			}
			
			if ($count > 1) {
				#had more than 1 <results> sections
				push @{$ret},$returns;
			}
			else {
				$ret = $returns;
			}
		}
		else {
			foreach my $res ($doc->getElementsByTagName($returns)) {
				$ret = $res->to_literal;
			}
		}
		
		if (!$ret) {
			$ret = $doc->findvalue('/');
		}
		return $ret;
	}
}
	
sub doHTTP {
	my $self = shift;
	
	my ($host,$soap,$soapaction,$lookfor) = @_;
	
	my $req = HTTP::Request->new(POST => $host);
	#ref $soap to save string copying back and forth...
	if (ref($soap)) {
		$req->content($$soap);
	}
	else {
		$req->content($soap);
	}
	
	$req->header('SOAPAction' => $soapaction);
	
	my $res = $self->{'ua'}->request($req);

	if ($res->is_success()) {
		$self->{'DEBUG'} and warn "Request successfull (200 OK) parsing response...\n";
		
		my $result = $self->parse_xml(\$res->content,$lookfor);
		
		return (1,$result);
	}
	else {
		if ($res->content) {
			$self->{'DEBUG'} and warn "Request unsuccessfull parsing response...\n";
			
			my $fault = $self->parse_xml(\$res->content,'Fault');
			return (0,$fault);
		}
		else {
			Carp::croak("request failed with ".$res->as_string."\n");
		}
	}
}
	
=head1 Revision History

 0.0.1 
	Initial Release
 0.0.2 
	Requisite XML::LibXML 1.62 specified in Makefile.PL
	Fixed some POD formatting issues
	Fixed some POD typos
 0.0.3
	Corrected tag ``ChargingInformation'' to ``charging'' in sub charging_info, as per documentation
	
=head1 Caveats
	
I really mean to split this to Mobile::Messaging::ParlayX::SMS, 
Mobile::Messaging::ParlayX::MMS and Mobile::Messaging::ParlayX::TS 
(Terminal Status), but I really ran out of time. Perhaps in the future (along with
better SOAP handling).
while on the subject of SOAP handling, I use XML::LibXML to validate all objects
before sending, receiving or processing them, but this is obviously one area that
needs quite a lot of work.
I`ve also done very little in terms of charsets, partly because my operator was in
no position to tell me and partly because I was lazy. I have no clue what happens
with GSM 03.38, UTF-8 and numeric encoded UTF-8 thrown in the mix. I`ve reached a
point where it works semi-reliably for me and - after I take a break - I`ll look 
further into this.

=head1 BUGS

Initial release...what did you expect ;) - well, not any more, but 0.0.2 fixes 
were purely cosmetic in nature.
Seriously now, most of the stuff is confirmed to work but probably not all angles 
are covered (in fact, I suspect very few are).

=head1 ACKNOWLEDGEMENTS

Obvious thanks to LWP::UserAgent, HTTP::Request and XML::LibXML authors, for none
of this would be possible without them (although some may argue that this would be
a good thing).
Big thanks should also go to Joshua Chamas for Apache::ASP and the mod_perl gurus.

=head1 AUTHOR

Thanos Chatziathanassiou <tchatzi@arx.net>
http://www.arx.net

=head1 COPYRIGHT

Copyright (c) 2007 arx.net - Thanos Chatziathanassiou . All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. 

=cut

1;
