#
# Net::SMS::TextMagic  This module provides access to TextMagic SMS service
#
# Author: Matti Lattu <matti@lattu.biz>
#
# Copyright (c) 2011 Matti Lattu. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# For TextMagic and its possible Copyright see http://www.textmagic.com/

package Net::SMS::TextMagic;

use strict;
use warnings;

our $VERSION = '1.00';

use JSON;
use LWP::UserAgent;
use URI::Escape qw(uri_escape uri_escape_utf8);
use Encode qw(encode decode);

=encoding utf8

=head1 SYNOPSIS

use Net::SMS::TextMagic;

 my $sms = Net::SMS::TextMagic->new( USER => $username, API_ID => $api_id );
 $sms->message_send(text=>'This is a test!', phone=>'35891911');

=head1 DESCRIPTION

TextMagic (http://www.textmagic.com) is a commercial service that allows its users to send
SMS messages to anyone in the world.

Net::SMS::TextMagic provides OO methods that allow to send SMS messages through
TextMagic service. The TextMagic HTTPS API is documented at
L<http://api.textmagic.com/https-api>. This module implements all HTTPS API commands
and return values.
However, all command parameters and return values are not necessary mentioned or thorougly
described in this document. Please consult the original API document for details.

Note that whether this software nor the author are related to TextMagic in any way.

=head1 METHODS

=over 4

=item new

Creates the TextMagic object.

Usage:

 my $sms = Net::SMS::TextMagic->new( USER => $username, API_ID => $api_id );

The complete list of arguments is:

B<USER>
Your TextMagic username. Same as your username to TextMagic web service.
Required.

B<API_ID>
Your TextMagic API ID. The API ID is not your password to TextMagic
web service. You can get your API ID from the
TextMagic web service. Required.

B<API_URL>
TextMagic API URL. Defaults to https://www.textmagic.com/app/api.

B<UserAgent>
Name of the user agent you want to display to TextMagic service.
Defaults to "Net::SMS::TextMagic"

B<Timeout>
UserAgent timeout. Defaults to 10 seconds.

Returns Net::SMS::TextMagic object or false (in case USER or API_ID are missing).

=cut

sub new {
	my ($class, %params) = @_;
	
	my $self = {};

	# Store TextMagic username (required)
	
	if ($params{'USER'}) {
		$self->{'USER'} = $params{'USER'};
		}
	else {
		# USER parameter is missing - return false
		return;
		}
	
	# Store TextMagic API ID (required)
	
	if ($params{'API_ID'}) {
		$self->{'API_ID'} = $params{'API_ID'};
		}
	else {
		# API_ID parameter is missing - return false
		return;
		}

	# Create LWP::UserAgent
	$self->{'UA'} = LWP::UserAgent->new;
	
	# Set TextMagic API URL (optional)
	
	if (defined($params{'API_URL'}) and $params{'API_URL'} ne '') {
		$self->{'API_URL'} = $params{'API_URL'};
		}
	else {
		$self->{'API_URL'} = 'https://www.textmagic.com/app/api';
		}

	# Set UserAgent string (optional)
	
	if (defined($params{'UserAgent'}) and $params{'UserAgent'} ne '') {
		$self->{'UA'}->agent($params{'UserAgent'});
		}
	else {
		$self->{'UA'}->agent('Net::SMS::TextMagic');
		}
	
	# Set UserAgent timeout (optional)
	
	if (defined($params{'Timeout'}) and $params{'Timeout'} ne '') {
		$self->{'UA'}->timeout($params{'Timeout'});
		}
	else {
		# Default timeout is 10 seconds
		
		$self->{'UA'}->timeout(10);
		}

	# Current error message
	$self->{'ERROR'} = undef;
	
	# Unprocessed error messages
	$self->{'ERROR_UNPROC'} = [];
	
	bless($self, $class);

	return $self;
	}

=item message_send

Sends SMS message. Equals to HTTPS API command "send" but renamed in
the module to avoid conflict with built-in send function.

Usage:

 my %response = $sms->message_send(text=>'This is a test!', phone=>'35891911');
 print "Sent message $response{'sent_text'} chopped in $response{'parts_count'} parts\n";

The complete list of arguments is:

B<text>
Message text in Perl internal charset. Required.

B<phone>
Phone number(s). The numbers are sent "as is". Currently the API supports up to
100 numbers separated by commas (,). Required.

B<unicode>
If set to true the message text is sent as UTF-8. Otherwise the text is sent
in GSM 03.38 encoding. Defaults to true (UTF-8).

B<from>, B<max_length>, B<send_time>
See TextMagic HTTPS API documentation.

Returns a hash containing following keys:

B<sent_text>
The text (in Perl internal charset) that was actually sent.

B<parts_count>
The number of parts the message has.

B<message_id>
A hash containing pairs of numbers (keys) and message_ids (values) that were
sent.

=cut

sub message_send {
	my ($class, %params) = @_;
	
	# Check for required parameters
	if ((!$params{'text'}) or (!$params{'phone'})) {
		set_error($class, "method 'message_send' was called without required parameters");
		return;
		}

	# UNICODE defaults to true
	if (!defined($params{'unicode'})) {
		$params{'unicode'} = 1;
		}
	
	if ($params{'unicode'}) {
		# Encode message as UTF8
		$params{'text'} = uri_escape($params{'text'});
		}
	else {
		# Encode message as GSM 03.38
		$params{'text'} = encode("gsm0338", $params{'text'});
		$params{'text'} = uri_escape($params{'text'});
		}
	
	my $r_json = contact_api($class, 'send', %params);
	
	if (defined($r_json)) {
		# No errors
		
		my %response = ();

		$response{'sent_text'} = $r_json->{'sent_text'};

		$response{'parts_count'} = $r_json->{'parts_count'};

		while (my ($id, $number) = each %{$r_json->{"message_id"}} ) {
			  $response{'message_id'}{$number} = $id;
			  }

		return %response;
		}
	else {
		# Errors, we expect that error flag was raised in contact_api()
		
		return;
		}
	}

=item account

Get the current SMS credit balance.

Usage:

 my %response = $sms->account();
 print "Your balance is $response{'balance'}\n";
 
Returns a hash containing following key:

B<balance>
The amount of available SMS credits on your account.

=cut

sub account {
	my ($class) = @_;
	
	my $r_json = contact_api($class, 'account');
	
	if (defined($r_json)) {
		# No errors
		
		my %response = ();
	
		$response{'balance'} = $r_json->{'balance'};
	
		return %response;
		}
	else {
		# Errors, we expect that error flag was raised in contact_api()
		
		return;
		}
	}
	
=item message_status

This method allows you to retrieve the delivery status of any SMS you have
already sent. The message ID is returned by message_send command.

Usage:

 my $this_id = 123456;
 my %response = $sms->message_status($this_id);
 print 'Message text was '.$response{$this_id}{'text'}."\n";
 print 'The cost was '.$response{$this_id}{'credits_cost'}." credits\n";

The only parameter is a string containing message ID or several IDs
separated by commas and without spaces (e.g. "8624389,8624390,8624391").
Up to 100 IDs can be retrieved with a single command.

Returns a two-level hash containing status of message IDs. Each ID has following
fields:

B<text>
SMS text sent.

B<status>
The current status of the message. The status codes are explained at
L<http://api.textmagic.com/https-api/sms-delivery-notification-codes>.

B<created_time>
The time TextMagic sent the message. Unix timestamp.

B<reply_number>
See API documentation for details.

B<credits_cost>
Cost of the message in SMS credits. Set when message is delivered.

B<completed_time>
The time your message achieves final status, returned by the mobile operator.
Unix timestamp.

=cut

sub message_status {
	my ($class, $ids) = @_;
	
	# Check for required parameters
	if (!$ids) {
		set_error($class, "method 'message_status' was called without parameters");
		return;
		}

	my %params = ('ids' => $ids);
	
	my $r_json = contact_api($class, 'message_status', %params);
	
	if (defined($r_json)) {
		# No errors
		
		my %response = ();

		foreach my $this_id (keys %{$r_json}) {
			$response{$this_id} = ();
			$response{$this_id}{'text'} = encode("utf8", $r_json->{$this_id}->{'text'});
			$response{$this_id}{'status'} = $r_json->{$this_id}->{'status'};
			$response{$this_id}{'created_time'} = $r_json->{$this_id}->{'created_time'};
			$response{$this_id}{'reply_number'} = $r_json->{$this_id}->{'reply_number'};
			$response{$this_id}{'credits_cost'} = $r_json->{$this_id}->{'credits_cost'};
			$response{$this_id}{'completed_time'} = $r_json->{$this_id}->{'completed_time'};
			}

		return %response;
		}
	else {
		# Errors, we expect that error flag was raised in contact_api()
		
		return;
		}
	}

=item receive

This method retrieves the incoming SMS messages from the server.
The server is limited to returning a maximum of 100 messages for
each request. Please use last_retrieved_id parameter to page through
your inbox.

The only optional parameter is B<last_retrieved_id>. The server will
only return messages with identifiers greater than B<last_retrieved_id>.
The default value is 0 which fetches up to the first 100 replies from
your inbox.

Returns a hash containing following keys:

B<unread>
The number of messages with identifiers greater than B<last_retrieved_id>
remaining unreturned due to the limit on returned messages per request.

B<messages_count>
Number of messages in the current B<messages> hash.

B<messages>
An array containing all messages. Each object in the array is a hash
with following keys:

=over 4

B<message_id>
The identifier of the incoming message.

B<from>
The sender's phone number.

B<timestamp>
The message's reception time expressed in Unix time format.

B<text>
The message text.

=back

=cut

sub receive {
	my ($class,$lrid) = @_;
	
	if (!defined($lrid)) {
		# Default value for last_retrieved_id
		$lrid = 0;
		}

	my %params = ('last_retrieved_id' => $lrid);
	
	my $r_json = contact_api($class, 'receive', %params);
	
	if (defined($r_json)) {
		# No errors
		
		my %response = ();

		$response{'unread'} = $r_json->{'unread'};
		$response{'messages_count'} = scalar(@{$r_json->{'messages'}});

		print "messages count: ".scalar(@{$r_json->{'messages'}})."\n";
		
		for (my $i=0; $i < scalar(@{$r_json->{'messages'}}); $i++) {
			my %this_msg_data = ();
			$this_msg_data{'message_id'} = @{$r_json->{'messages'}}[$i]->{'message_id'};
			$this_msg_data{'from'} = @{$r_json->{'messages'}}[$i]->{'from'};
			$this_msg_data{'timestamp'} = @{$r_json->{'messages'}}[$i]->{'timestamp'};
			$this_msg_data{'text'} = encode("utf8", @{$r_json->{'messages'}}[$i]->{'text'});
			push(@{$response{'messages'}}, {%this_msg_data});
			}

		return %response;
		}
	else {
		# Errors, we expect that error flag was raised in contact_api()
		
		return;
		}
	}

=item delete_reply

This command helps you to delete any incoming SMS messages from the server.

Usage:

 my @response = $sms->delete_reply('123456,123457,123458');
 print "Following messages were deleted: ".join(', ', @response)."\n";

The only required parameter is a string containing message IDs to be deleted.
The IDs should be separated with commas without spaces. Up to 100 messages
can be deleted with single command.

Returns an array containing message IDs that were deleted.

=cut

sub delete_reply {
	my ($class, $delids) = @_;
	
	if (!defined($delids)) {
		set_error($class, "method 'delete_reply' was called without parameters");
		return;
		}

	my %params = ('ids' => $delids);
	
	my $r_json = contact_api($class, 'delete_reply', %params);
	
	if (defined($r_json)) {
		# No errors
		
		return @{$r_json->{'deleted'}};
		}
	else {
		# Errors, we expect that error flag was raised in contact_api()
		
		return;
		}
	}

=item check_number

This command helps you to validate a phone number's format and to check a
message's price to its destination.

Usage:

 my %response = $sms->check_number('35891911,35891912');
 
 foreach my $this_number (keys %response) {
   print "Number $this_number is in ".
     $response{$this_number}{'country'}.
     'and the SMS cost is '.
     $response{$this_number}{'price'}.
     "credits.\n";
   }

The only required parameter is a string containing phone numbers to be checked.
The numbers should be separated with commas without spaces. The TextMagic HTTPS
API documentation does not specify the maximum number of phone numbers that
can be checked with a single command.

Returns a two-level hash containing status of numbers. Each number has following
fields:

B<price>
The cost in SMS credits of sending a single message to the number.

B<country>
The number's country code. A full list of country codes can be found at
L<https://www.textmagic.com/app/wt/messages/new/cmd/get_countries>.

=cut

sub check_number {
	my ($class, $numbers) = @_;
	
	if (!defined($numbers)) {
		set_error($class, "method 'check_number' was called without parameters");
		return;
		}

	my %params = ('phone' => $numbers);
	
	my $r_json = contact_api($class, 'check_number', %params);
	
	if (defined($r_json)) {
		# No errors
		
		my %response = ();
		
		foreach my $this_number (keys %{$r_json}) {
			$response{$this_number}{'price'} = $r_json->{$this_number}->{'price'};
			$response{$this_number}{'country'} = $r_json->{$this_number}->{'country'};
			}

		return %response;
		}
	else {
		# Errors, we expect that error flag was raised in contact_api()
		
		return;
		}
	}

=item contact_api

Contacts TextMagic API. This in mainly for internal use, but can be used
to contact TextMagic API directly.

Usage:

 my $r_json = $sms->contact_api('some_api_command', %parameters);

Parameters:
- a string containing TextMagic HTTPS API command
- a hash containing command parameters

Returns a JSON object containing the result.

=cut

sub contact_api {
	my ($class, $cmd, %params) = @_;
	
	$params{'cmd'} = $cmd;
	$params{'username'} = $class->{'USER'};
	$params{'password'} = $class->{'API_ID'};
	
	my $response = $class->{'UA'}->post($class->{'API_URL'}, Content=>\%params);
	
	if ($response->is_success) {
		# For debugging
		# print "---JSON begins:\n".$response->decoded_content."\n---JSON ends\n";
		my $json_obj = decode_json($response->decoded_content);
		if ($json_obj->{'error_code'}) {
			# API error, set error message
			
			set_error($class, 'API error #'.$json_obj->{'error_code'}.': '.$json_obj->{'error_message'});
			return;
			}
		else {
			# API ok, return JSON object
			
			return $json_obj;
			}
		}
	else {
		# HTTP POST failed
		set_error($class, "HTTP POST failed: ".$response->status_line);
		return;
		}
	}

=item set_error

Sets Net::SMS::TextMagic error code. Mainly for internal use.

If there is already an unprocessed error message, this message
is appended to the unprocessed error array. The array can be read
and emptied with get_unprocessed_errors().

Usage:

 $sms->set_error('Out of credit');

=cut

sub set_error {
	my ($class, $errormsg) = @_;
	
	# If there are alredy current error, add error to error buffer
	if ($class->{'ERROR'}) {
		push(@{$class->{'ERROR_UNPROC'}}, $class->{'ERROR'});
		}
		
	$class->{'ERROR'} = $errormsg;
	
	return 1;
	}

=item get_error

Gets and clears Net::SMS::TextMagic error code. This does not affect the 
array of unprocessed error messages (see get_unprocessed_errors()).

Usage:

 my %response = $sms->message_send('phone' => '123456', 'text' => 'Howdy!');
 if ($sms->if_error()) {
   my $errormsg = $sms->get_error();
   if ($errormsg) {
     print "Dough! $errormsg\n"; 
 	  }
 	}

No parameters. Returns a error string if error flag is up. If no error message is
present returns undef.

=cut

sub get_error {
	my ($class) = @_;
	
	my $errormsg = $class->{'ERROR'};
	$class->{'ERROR'} = undef;
	
	return $errormsg;
	}

=item if_error

Returns true if there is a pending error code (see get_error()).
Returns false if no error flag is set.

Usage:

 if ($sms->if_error()) {
   print STDERR "SMS error: ".$sms->get_error()."\n";
   }
   
=cut

sub if_error {
	my ($class) = @_;
	
	if ($class->{'ERROR'}) {
		return 1;
		}
	else {
		return;
		}
	}

=item get_unprocessed_errors

Returns and flushes the array of unprocessed errors. See set_error().

=cut

sub get_unprocessed_errors {
	my ($class) = @_;
	
	my @errors = @{$class->{'ERRORS_UNPROC'}};
	
	$class->{'ERRORS_UNPROC'} = [];
	
	return @errors;
	}

=item if_unprocessed_errors

Returns a number of items in the array of unprocessed errors. If
there are no errors returns undef (false).

=back

=cut

sub if_unprocessed_errors {
	my ($class) = @_;
	
	my $n = scalar(@{$class->{'ERRORS_UNPROC'}});
	
	if ($n == 0) {
		return;
		}
	
	return $n;
	}
	
1;

__END__

=head1 BUGS

Since the author uses this module mostly for sending SMSs not all features
related to receiving a great number of messages has been tested. Do not
hesitate to contact if you suspect bugs.

=head1 AUTHOR

Matti Lattu, <matti@lattu.biz>

=head1 ACKNOWLEDGEMENTS

The documentation has a great number of verbatim quotations of TextMagic HTTPS
API documentation.

Greatly inspired by "official" TextMagic Perl API implementation
(L<http://code.google.com/p/textmagic-sms-api-perl/>) by Marco-Paul Breijer
and Net::SMS::Clickatell by Robert Moreno.

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

Copyright (C) 2011 Matti Lattu

=cut
