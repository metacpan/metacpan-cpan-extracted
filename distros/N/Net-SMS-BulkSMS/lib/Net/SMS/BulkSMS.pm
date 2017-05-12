package Net::SMS::BulkSMS;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.02';

use Carp;
use HTTP::Request::Common;
use LWP::UserAgent;
use MIME::Base64;
use POSIX qw(strftime);


sub new
{
   my $class = shift;

   my $this = {
		test				=> 0,
		test_form_url	=> "http://setyoururlhere/cgi-bin/form.pl/",
      username    	=> undef,
      password    	=> undef,
      max_recipients	=> 200,
		num_retries		=> 3,
      signature		=> "",
      signature_datetime	=> 1,
		sender			=> "BulksmsCoUk",
      url         	=>
      {
         base        	=> 'http://www.bulksms.co.uk:7512/eapi/1.0/',
         get_credits 	=> "get_credits.mc",
         send_sms    	=> "send_sms.mc",
         quote_sms   	=> "quote_sms.mc",
         get_report  	=> "get_report.mc",
         phonebook_public_add_member   => "phonebook/public_add_member",
         phonebook_public_remove_member => "phonebook/public_remove_member",
      },

      @_,

		max_msglen		=> 160,
		max_senderlen	=> 11,
      max_length		=> 160,
   	VERSION			=> "0.1",
      };
   bless($this,$class);
   $this->init;
   $this;
}

sub init
{
   my $this = shift;
   if ( $this->{test} )
   {
   	$this->{url}->{base} = $this->{test_form_url};
   	$this->{username} = encode_base64("test");
   	$this->{password} = encode_base64("1234");
   }
   confess "need auth info" unless $this->{password} && $this->{username};
   $this->{username} = decode_base64($this->{username});
   $this->{password} = decode_base64($this->{password});
   1;
}

sub transaction
{
	my $this = shift;
	ref($this) or confess;
	my %arg = ( txn => undef, username => $this->{username}, password => $this->{password}, @_ );

	# construct URL to call web API
   my $url = $this->{url}->{base};
   confess unless $url;
   $url .= "/" unless $url =~ m/\/$/;
	confess "expected txn" unless $arg{txn};
   $url .= $this->{url}->{$arg{txn}} || confess "suburl for transaction $arg{txn} not defined";
	delete $arg{txn};

	# enforce 11 char limit on sender name/phone
	if ( defined $arg{sender} )
	{
		my $count = length($arg{sender});
		my $max_length = $this->{max_senderlen} || 11;
		return("Sender length $count too long (over $max_length characters)",0) if $count > $max_length;
	}

	# enforce 160 char limit on message length
	if ( defined $arg{message} )
	{
		$arg{message} =~ s/^\s+//; # trim spaces leading and trailing
		$arg{message} =~ s/\s+$//;
		my $count = length($arg{message});
		my $max_length = $this->{max_msglen} || 160;
		return("Message length $count too long (over $max_length characters including signature)",0) if $count > $max_length;
	}

	# special check on phone number array argument if present
	if ( defined $arg{msisdn} )
	{
		# strip white space
		my $s = $arg{msisdn};
		$s =~ s/\s//g; 
		$arg{msisdn} = $s;
		# split to individual phone numbers on comma
		my @telno = split(/\,/,$s);
		$s =~ s/\,//g; # strip commas and check for non-digits
		return ("Phone number string msisdn contains non-digits: $arg{msisdn}",0) if $s =~ m/\D/;
		# check for duplicate phone numbers
		my %h;
		for (@telno) { $h{$_}++; }
		my @dupno;
		for ( keys %h )
		{
			push(@dupno,$_) if $h{$_} > 1;
		}
		return("Phone number string msisdn contains duplicate phone numbers : ".join(",",@dupno)." in $arg{msisdn}",0) if scalar @dupno > 0;
		# check count of phone numbers
		return("Phone number string msisdn contains no phone numbers: $arg{msisdn}",0) if scalar @telno <= 0;
		my $max_recipients = $this->{max_recipients} || 0;
		my $count = scalar @telno;
		if ( $max_recipients && $count > $max_recipients )
		{
			return("Cannot send more than $max_recipients messages at once ($count phone numbers in list)",0);
		}
	}

	# delete undefined parameters
	for ( keys %arg )
	{
		delete $arg{$_} unless defined $arg{$_};
	}

   my $req = POST $url, [ %arg ];

   my $ua = LWP::UserAgent->new;
   $ua->env_proxy(); # allow for loading of proxy settings from *_proxy env vars; see "perldoc LWP::UserAgent" for details
	my $res = $ua->request($req);
	
   if ( $res->is_success ) # web request worked
   {
      return ($res->content, 1);
   }
   elsif ( $res->is_error ) # web request failed
   {
      return ($res->code . ": " . $res->message, 0);
   }
   else # redirect or information - should not happen, treat as failure
   {
      return (
         ( "Code: " . $res->code . "\n"
         . "Message: " . $res->message . "\n"
         . "Content: " . $res->content . "\n" )
         , 0);
   }
}

sub get_credits
{
	$_[0]->transaction ( txn => "get_credits" );
}

# send_sms - send an SMS text message
# 
# required parameters
# 	message: max 160 chars, 280 for 8bit
# 	msisdn: comma separated list of recipient phone numbers
# 
# optional parameters
# 	sender: sender id (if alphanumeric, max 11 characters). This facility has to be specifically enabled for your account on request. Alphanumeric sender id is a route-specific feature. 
# 	msg_class: currently 0 (flash SMS) or 2 (normal SMS), default 2 
# 	dca: Data Coding Alphabet: 7bit,8bit or 16bit, default 7bit (normal text message). For 8bit (ringtones,logos) or 16bit (Unicode), a message containing only hexadecimal octets, to a maximum of 280 characters (140 octet pairs), must be submitted. Currently, concatenation is not supported for Unicode messages. 16-bit is a route-specific feature. 
# 	want_report: 0 or 1, default 0 
# 	cost_route: 1 or 2, default 1 (future functionality - always use 1 for now, if used) 
# 	msg_id: a unique id generated by yourself, to reduce risk of duplicate submissions - future functionality, currently unused. 
# 
# returns
#	 status_code|status_description|message_id (where message_id is optional, depending on the error) 
# 
# status codes
# 	0: In progress (a normal message submission, with no error encountered so far). 
# 	22: Internal fatal error 
# 	23: Authentication failure 
# 	24: Data validation failed 
# 	25: You do not have sufficient credits 
# 	26: Upstream credits not available 
# 	27: You have exceeded your daily quota 
# 	28: Upstream quota exceeded 
# 	40: Temporarily unavailable 
# 

sub base_send_sms
{
	my $this = shift;
	my %arg = (
		## mandatory
		message		=> undef,
		msisdn		=> undef,
		## optional
		sender		=> $this->{sender}, # sender id, alphanumeric, max 11 chars
		msg_class	=> "2", # 2 = normal SMS, 0 = flash SMS
		dca			=> "7bit", # data coding alphabet: 7bit (default), 8bit (ringtones,logos), 16bit (Unicode)
		want_report	=> 1, # 0 or 1
		cost_route	=> 1, # 1 or 2, default 1, 2 not implemented
		#msg_id		=> our unique id
		## user
		quote			=> 0,
		@_,
		);
	confess unless $arg{message} && $arg{msisdn};
	my $txn = $arg{quote} ? "quote_sms" : "send_sms";
	$arg{message} .= $this->{signature};
	my $datetime = strftime "%e-%b-%Y %H:%M", localtime(time);
	$arg{message} .= "\n$datetime" if $this->{signature_datetime};

	# call HTTP web request API interface at bulksms
	# on HTTP status code <> 200 we should try resending a few times
	my ($webmsg,$webcode);
	for (1..($this->{num_retries}||3))
	{
		($webmsg,$webcode) = $this->transaction (
			txn			=> $txn,
			message		=> $arg{message},
			msisdn		=> $arg{msisdn},
			msg_class	=> $arg{msg_class},
			dca			=> $arg{dca},
			want_report	=> $arg{want_report},
			cost_route	=> $arg{cost_route},
			sender		=> $arg{sender},
			);
		return ($webmsg,1) if $webcode; # web request success
		select(undef,undef,undef,0.25); # wait 0.25 seconds
	}
	return ($webmsg,0); # web request failed
}

sub send_sms
{
	my $this = shift;
	# try and send, retry on temporary error (code 40)
	# possibly should retry on 26-28 or warn user about account/quota limit at caller's level
	my ($code,$desc,$msg_id);
	for (1..($this->{num_retries}||3))
	{
		my ($webmsg,$webcode) = $this->base_send_sms ( @_ );
		return ($webmsg,0) unless $webcode; # web request failed
		($code,$desc,$msg_id) = split(/\|/,$webmsg,3);
		$desc ||= "";
		return ("$msg_id",1) if $code eq "0"; # code 0 == in progress (successful)
		return ("$code: $desc",0) if $code ne "40"; # outright failure, except 40 which is temporary
		select(undef,undef,undef,0.25); # wait 0.25 seconds before retry
	}
	return ("$code: $desc",0); # failure
}

sub quote_sms
{
	my $this = shift;
	my ($webmsg,$webcode) = $this->base_send_sms ( @_, quote => 1 );
	return ($webmsg,0) unless $webcode; # web request failed
	my ($code,$desc,$quote_total) = split(/\|/,$webmsg,3);
	$desc ||= "";
	return ("$quote_total",1) if $code eq "1000"; # code 1000 == successful quotation
	return ("$code: $desc",0); # failure
}

# get_report - report status of a sent SMS text message
# 
# required parameters
# 	msg_id: message id return by send_sms
# optional parameter
# 	msisdn: supply if querying the status of a single recipient. 
# 
# returns on failure
# 	desc: "request_status_code: desc" formatted request status code and description
# 	code: 0
# 	result: undefined
# 
# 	possible request status codes
# 		23: Authentication failure 
# 		24: Data validation failed 
# 		1001: Error - message not found (msg_id incorrect)
# 
# returns on success
# 	desc: "request status code: description", code 1000, description
# 				"Results to follow\n" followed by one or more newline-separated items in the format:
# 				"msisdn|status_code|status_description"
# 	code: 1
# 	result: pointer to results hash indexed by msisdn (phone number),
# 		each entry a pointer to hash of {code,desc}
# 	
# status codes and descriptions:
# 
# 	0: In progress (a normal message submission, with no error encountered so far). 
# 	10: Delivered upstream 
# 	11: Delivered to mobile 
# 	22: Internal fatal error 
# 	23: Authentication failure 
# 	24: Data validation failed 
# 	25: You do not have sufficient credits 
# 	26: Upstream credits not available 
# 	27: You have exceeded your daily quota 
# 	28: Upstream quota exceeded 
# 	29: Message sending cancelled 
# 	30: Test complete (you should never see this) 
# 	40: Temporarily unavailable 
# 	50: Delivery failed - generic failure 
# 	51: Delivery to phone failed 
# 	52: Delivery to network failed 
# 	60: Transient upstream failure (transient) 
# 	61: Upstream status update (transient) 
# 	62: Upstream cancel failed (transient) 
# 	70: Unknown upstream status 

sub get_report
{
	my $this = shift;
	my %arg = ( msg_id => undef, msisdn => undef, @_ );
	confess unless defined $arg{msg_id};
	my ($webmsg,$webcode) = $this->transaction ( txn => "get_report", msg_id => $arg{msg_id}, msisdn => $arg{msisdn} );
	return ($webmsg,0,undef) unless $webcode; # web request failed
	# check bulksms API return
	my ($code,$desc) = split(/\|/,$webmsg,2);
	$desc ||= "";
	return ("$code: $desc",0,undef) if $code ne "1000"; # failure (1001,23,24) (code 1000 = success)
	# API returns on success a string containing
	#		1000|Results to follow\n Followed by one or more newline-separated items in the format:
	#		msisdn|status_code|status_description
	# build result hash from this
	my @l = split(/\n/,$desc);
	shift @l; # remove "Results to follow" first line
	my %h;
	for (@l)
	{
		my ($msisdn,$status_code,$status_desc) = split(/\|/,$_);
		$h{$msisdn} = { code => $status_code, desc => $status_desc };
	}
	return ("$code: $desc",1,\%h); # success
}

sub phonebook_public_add_member
{
	confess "not implemented";
}

sub phonebook_public_remove_member
{
	confess "not implemented";
}


1;
__END__

=head1 NAME

Net::SMS::BulkSMS - send SMS messages via provider bulksms.co.uk

=head1 SYNOPSIS

 use Net::SMS::BulkSMS;

 my ($sms,$msg,$code,$result_hp,$msg_id,$credits);

 $sms = Net::SMS::BulkSMS->new (username=>"aaaaaaaaaaaa", password=>"bbbbbbbbbbbb", sender => "SomeCoUk");
 or
 $sms = Net::SMS::BulkSMS->new (test => 1, test_form_url => "mycompany.co.uk/cgi-bin/form.pl/");

 ($credits,$code) = $sms->get_credits;
 ($credits,$code) = $sms->quote_sms (message=>"Testing", msisdn=>"44123123456");
 ($credits,$code) = $sms->quote_sms (message=>"Testing", msisdn=>"44123123456", msg_class=>"0");
 ($msg_id,$code) = $sms->send_sms (message=>"Testing 1", msisdn=>"44123123456");
 ($msg_id,$code) = $sms->send_sms (message=>"Testing 2", msisdn=>"44123123456,44567567890");
 ($msg,$code,$result_hp) = $sms->get_report (msg_id=>$msg_id);
 ($msg,$code,$result_hp) = $sms->get_report (msg_id=>$msg_id, msisdn=>"44123123456");

=head1 DESCRIPTION

This module provides an SMS transport mechanism for the gateway bulksms.co.uk.
You will need to create an account at www.bulksms.co.uk and obtain a username and password,
then you can use this module to send and query the status of SMS messages.
The transport mechanism is via the HTTP API published at http://www.bulksms.co.uk/docs/eapi/current/.

=head1 ABSTRACT

Net::SMS::BulkSMS provides a calling interface and transport to send SMS text messages
via the gateway bulksms.co.uk.

=head1 CONSTRUCTOR

Create a new BulkSMS object:

=over 4

=item $sms = Net::SMS::BulkSMS->new ( [ test => 1, ] username => $username, password => $password,
	[ sender => $sender, ] [ signature => $signature, ] [ signature_datetime => 0, ] 
	[ max_recipients => $max_recipients, ] [ num_retries => $num_retries ] )

This class method constructs an BulkSMS object. You must either supply a valid
username and password for an account at bulksms.co.uk, or set test => 1 and provide
test_form_url pointing to a script that will print posted form arguments so you
can debug your SMS interface without sending real messages.

The remaining parameters are optional and override built-in defaults.

=item username password

Valid details for an account at bulksms.co.uk, encoded in base64 L<MIME::Base64>.

=item test

True/False(default). When true turns on test mode, no messages will be sent, and HTTP requests
will be sent to test_form_url instead of bulksms.co.uk's eapi.

=item sender

Up to 11 alphanumeric characters, either the mobile number to reply to or a company name.

=item signature

Text to append to each sent message, e.g. "\nAcmeCoUk".

=item signature_datetime

True(default)/False. Whether to append a date time stamp after signature.

=item max_recipients

Number, default 200. Maximum number of phone numbers allowed when sending the same message to
multiple recipients. Set to 0 for unlimited.

=item num_retries

Number, default 3. Number of times the transport retries posting HTTP requests before failing.

=head1 METHODS

The following methods work with a created BulkSMS object.

=over 4

=item B<get_credits>

Fetches the available credit balance on the bulksms account.

Returns

	success: (credits,1) credits is a string representation of credit balance to two floating points
	failure: ("errorcode: errormessage",0)

=item B<quote_sms>

Parameters

Takes exactly the same parameters as the B<send_sms> method, and quotes
how many credits it would take to fulfil the request via send_sms.

Returns

	success: (credits,1) credit is a string representation of number of credits required to send a
message with the specified parameters
	failure: ("errorcode: errormessage",0)

=item B<send_sms>

Send an SMS message to one or more recipients.

Required parameters
	message: max 160 chars, 280 for 8bit
	msisdn: comma separated list of recipient phone numbers

Optional parameters
	sender: sender id (if alphanumeric, max 11 characters). This facility has to be specifically enabled for your account on request. Alphanumeric sender id is a route-specific feature. 
	msg_class: currently 0 (flash SMS) or 2 (normal SMS), default 2 
	dca: Data Coding Alphabet: 7bit,8bit or 16bit, default 7bit (normal text message). For 8bit (ringtones,logos) or 16bit (Unicode), a message containing only hexadecimal octets, to a maximum of 280 characters (140 octet pairs), must be submitted. Currently, concatenation is not supported for Unicode messages. 16-bit is a route-specific feature. 
	want_report: 0 or 1, default 1
	cost_route: 1 or 2, default 1 (future functionality - always use 1 for now, if used) 
	msg_id: a unique id generated by yourself, to reduce risk of duplicate submissions - future functionality, currently unused. 

Returns
	success: ($msg_id, 1)
	failure: ("errorcode: errormessage", 0)

	error codes
	0: In progress (a normal message submission, with no error encountered so far). 
	22: Internal fatal error 
	23: Authentication failure 
	24: Data validation failed 
	25: You do not have sufficient credits 
	26: Upstream credits not available 
	27: You have exceeded your daily quota 
	28: Upstream quota exceeded 
	40: Temporarily unavailable 

=item B<get_report>

Get a status report on a sent message batch by msg_id.

Required parameters
	msg_id: message id returned from send_sms

Optional parameter
	msisdn: comma separated list of phone no.s by which to restrict report

Returns
	failure: ("errorcode: errormessage",1,undef)
	success: ($msg,0,$result_hash_ptr)
		$msg is eapi message, $result_hash_ptr is eapi message broken down
		to a hash of entries by phone no. containing { code, desc } from this table

	0: In progress (a normal message submission, with no error encountered so far). 
	10: Delivered upstream 
	11: Delivered to mobile 
	22: Internal fatal error 
	23: Authentication failure 
	24: Data validation failed 
	25: You do not have sufficient credits 
	26: Upstream credits not available 
	27: You have exceeded your daily quota 
	28: Upstream quota exceeded 
	29: Message sending cancelled 
	30: Test complete (you should never see this) 
	40: Temporarily unavailable 
	50: Delivery failed - generic failure 
	51: Delivery to phone failed 
	52: Delivery to network failed 
	60: Transient upstream failure (transient) 
	61: Upstream status update (transient) 
	62: Upstream cancel failed (transient) 
	70: Unknown upstream status 

=head1 SEE ALSO

L<MIME::Base64>

=head1 AUTHOR

C<Net::SMS::BulkSMS> was developed by Peter Edwards <peter@dragonstaff.co.uk>.

=head1 COPYRIGHT

Copyright 2007 Peter Edwards <peter@dragonstaff.co.uk>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
