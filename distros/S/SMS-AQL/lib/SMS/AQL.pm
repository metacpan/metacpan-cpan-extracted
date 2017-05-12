package SMS::AQL;

# SMS::AQL - Sends text messages via AQL's gateway
#
# David Precious, davidp@preshweb.co.uk
#
# $Id$


use 5.005000;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use HTTP::Request;
use vars qw($VERSION);

$VERSION = '1.02';

my $UNRECOGNISED_RESPONSE = "Unrecognised response from server";
my $NO_RESPONSES = "Could not get valid response from any server";

=head1 NAME

SMS::AQL - Perl extension to send SMS text messages via AQL's SMS service

=head1 SYNOPSIS

  # create an instance of SMS::AQL, passing it your AQL username
  # and password (if you do not have a username and password, 
  # register at www.aql.com first).
  
  $sms = new SMS::AQL({
    username => 'username',
    password => 'password'
  });

  # other parameters can be passed like so:
  $sms = new SMS::AQL({
    username => 'username',
    password => 'password',
    options => { sender => '+4471234567' }
  });
  
  # send an SMS:
  
  $sms->send_sms($to, $msg) || die;
  
  # called in list context, we can see what went wrong:
  my ($ok, $why) = $sms->send_sms($to, $msg);
  if (!$ok) {
      print "Failed, error was: $why\n";
  }
  
  # params for this send operation only can be supplied:
  $sms->send_sms($to, $msg, { sender => 'bob the builder' });
  
  # make a phone call and read out a message:
  my ($ok, $why) = $sms->voice_push($to, $msg);

  

=head1 DESCRIPTION

SMS::AQL provides a nice object-oriented interface to send SMS text
messages using the HTTP gateway provided by AQ Ltd (www.aql.com) in 
the UK.

It supports concatenated text messages (over the 160-character limit
of normal text messages, achieved by sending multiple messages with
a header to indicate that they are part of one message (this is
handset-dependent, but supported by all reasonably new mobiles).



=head1 METHODS

=over

=item new (constructor)

You must create an instance of SMS::AQL, passing it the username and
password of your AQL account:

  $sms = new SMS::AQL({ username => 'fred', password => 'bloggs' });
  
You can pass extra parameters (such as the default sender number to use,
or a proxy server) like so:

  $sms = new SMS::AQL({
    username => 'fred', 
    password => 'bloggs',
    options  => {
        sender => '+44123456789012',
        proxy  => 'http://user:pass@host:port/',
    },
  });

=cut

sub new {

    my ($package, $params) = @_;

     if (!$params->{username} || !$params->{password}) {
         warn 'Must supply username and password';
         return undef;
     }

    my $self = bless { contents => {} } => 
        ($package || 'SMS::AQL');

    # get an LWP user agent ready
    $self->{ua} = new LWP::UserAgent;
    $self->{ua}->agent("SMS::AQL/$VERSION");
    
    # configure user agent to use a proxy, if requested:
    # TODO: validate supplied proxy details
    if ($params->{options}->{proxy}) {
        $self->{ua}->proxy(['http','https'] => $params->{options}->{proxy});
    }
    
    # remember the username and password
    ($self->{user}, $self->{pass}) = 
        ($params->{username}, $params->{password});
        
        
    # remember extra params:
    $self->{options} = $params->{options};
    
    # the list of servers we can try:
    $self->{sms_servers} = [qw(
        gw.aql.com
    )];
    
    $self->{voice_servers} = ['vp1.aql.com'];
    
    # remember the last server response we saw:
    $self->{last_response} = '';
    $self->{last_response_text} = '';
    $self->{last_error} = '';
    $self->{last_status} = 0;
        
    return $self;	
}



=item send_sms($to, $message [, \%params])

Sends the message $message to the number $to, optionally
using the parameters supplied as a hashref.

If called in scalar context, returns 1 if the message was
sent, 0 if it wasn't.

If called in list context, returns a two-element list, the
first element being 1 for success or 0 for fail, and the second
being a message indicating why the message send operation
failed.

You must set a sender, either at new or for each send_sms call.

Examples:
    
  if ($sms->send_sms('+44123456789012', $message)) {
      print "Sent message successfully";
  }
  
  my ($ok, $msg) = $sms->send_sms($to, $msg);
  if (!$ok) {
      print "Failed to send the message, error: $msg\n";
  }
  
=cut

sub send_sms {

    my ($self, $to, $text, $opts) = @_;
    
    $to =~ s/[^0-9+]//xms;

    # assemble the data we need to POST to the server:
    my %postdata = (
        username => $self->{user}, 
        password => $self->{pass},
        orig     => $opts->{sender} || $self->{options}->{sender}, 
        to_num   => $to,
        message  => $text,
    );
    
    if (!$postdata{orig}) {
	$self->{last_error} = "Cannot send message without sender specified";
	warn($self->{last_error});
        return 0;
    }
    
    my $response = 
        $self->_do_post($self->{sms_servers}, 
            '/sms/postmsg-concat.php', \%postdata);
    
    if ($response && $response->is_success) {
        $self->_check_aql_response_code($response);
        return wantarray ? 
            ($self->last_status, $self->last_response_text) : $self->last_status;
    }

    # OK, we got no response from any of the servers we tried:
    $self->_set_no_valid_response;
    return wantarray ? (0, $self->last_error) : 0;
	
} # end of sub send_sms



=item voice_push($to, $message [, \%params])

Make a telephone call to the given phone number, using speech synthesis to
read out the message supplied.

$to and $message are the destination telephone number and the message to read
out.  The third optional parameter is a hashref of options to modify the
behaviour of this method - currently, the only option is:

=over 4

=item skipintro

Skips the introductory message that AQL's system normally reads out. (If you
use this, it's recommended to add your own introduction to your message, for
example "This is an automated call from ACME Inc...")

=back

If called in scalar context, returns 1 if the message was sent, 0 if it wasn't.

If called in list context, returns a two-element list, the first element being 
1 for success or 0 for fail, and the second being a message indicating why the 
operation failed.

Note that, at the current time, this feature supports only UK telephone numbers.

=cut

sub voice_push {

    my ($self, $to, $text, $opts) = @_;
    
    if (!$to) {
        carp "SMS::AQL->voice_push() called without destination number";
        return;
    }
    
    if (!$text) {
        carp "SMS::AQL->voice_push() called without message";
        return;
    }
    
    # voice push only works for UK numbers, and does not accept international
    # format.  If the number was given in +44 format, turn it into standard
    # UK format; if it's an non-UK number, don't even try to send.
    $to =~ s{^\+440?}{0};
    
    if ($to !~ m{^0}) {
        carp "SMS::AQL->voice_push() called with a non-UK telephone number";
        return;
    }
    
    my %postdata = (
        username    => $self->{user}, 
        password    => $self->{pass},
        msisdn      => $to,
        message     => $text,
    );
    
    if ($opts->{skipintro}) {
        $postdata{skipintro} = 1;
    }
    
    
    my $response = $self->_do_post(
        $self->{voice_servers}, '/voice_push.php', \%postdata
    );
    
    if ($response && $response->is_success) {
        my $status = (split /\n/, $response->content)[0];
        
        my %response_lookup = (
            VP_OK => {
                status  => 1,
                message => 'OK',
            },
            VP_ERR_NOTOMOBNUM => {
                status  => 0,
                message => 'Telephone number not provided',
            },
            VP_ERR_INVALID_MOBNUM => {
                status  => 0,
                message => 'Invalid telephone number',
            },
            VP_ERR_NOTGLOBAL => {
                status  => 0,
                message => 'Voice push is currently only available for'
                    . ' UK telephone numbers',
            },
            VP_ERR_NOCREDIT => {
                status  => 0,
                message => 'Insufficient credit',
            },
            VP_ERR_INVALIDAUTH => {
                status  => 0,
                message => 'Username/password rejected',
            },
            VP_ERR_NOAUTH => {
                # we should never see this, as we fail to create SMS::AQL
                # instance without a username and password
                status  => 0,
                message => 'Username/password not supplied',
            },
            VP_ERR_NOMSG => {
                status  => 0,
                message => 'Message not provided',
            },
        );
        
        my $response_details = $response_lookup{$status};
        
        if (!$response_details) {
            warn "Unrecognised status '$status' from AQL";
            $response_details = { 
                status  => 0, 
                message => 'Unrecognised response',
            };
        }
        
        $self->{last_response} = $status;
        $self->{last_response_text} = $response_details->{message};
        $self->{last_status} = $response_details->{status};
        
        return wantarray ? 
            @$response_details{qw(status message)} : $response_details->{status};
            
    } else {
        # no response received:
        $self->{last_response} = '';
        $self->{last_response_text} = 'No response from AQL servers';
        $self->{last_status} = 0;
        return wantarray ?
            (0, 'No response from AQL servers') : 0;
    }

}



=item credit()

Returns the current account credit. Returns undef if any errors occurred

=cut

sub credit {

    my $self = shift;

    # assemble the data we need to POST to the server:
    my %postdata = (
        'username' => $self->{user}, 
        'password' => $self->{pass},
        'cmd'      => 'credit',
    );
    
    # try the request to each sever in turn, stop as soon as one succeeds.
    for my $server (sort { (-1,1)[rand 2] } @{$self->{sms_servers}} ) {
        
        my $response = $self->{ua}->post(
            "http://$server/sms/postmsg.php", \%postdata);
    
        next unless ($response->is_success);  # try next server if we failed.
    
        $self->_check_aql_response_code($response);
        
        my ($credit) = $response->content =~ /AQSMS-CREDIT=(\d+)/;
        
        return $credit;
        
   }
    
   $self->_set_no_valid_response;
   return undef;
} # end of sub credit



=item last_status()

Returns the status of the last command: 1 = OK, 0 = ERROR.

=cut

sub last_status { shift->{last_status} }

=item last_error()

Returns the error message of the last failed command.

=cut

sub last_error { shift->{last_error} }

=item last_response()

Returns the raw response from the AQL gateway.

=cut

sub last_response { shift->{last_response} }

=item last_response_text()

Returns the last result code received from the AQL
gateway in a readable format.

Possible codes are:

=over

=item AQSMS-AUTHERROR

The username and password supplied were incorrect

=item AQSMS-NOCREDIT

Out of credits (The account specified did not have sufficient credit)

=item AQSMS-OK

OK (The message was queued on our system successfully)

=item AQSMS-NOMSG

No message or no destination number were supplied

=back

=cut

my %lookup = (
	"AQSMS-AUTHERROR" => { 
		text => "The username and password supplied were incorrect", 
		status => 0,
		},
	"AQSMS-NOCREDIT" => { 
		#text => "The account specified did not have sufficient credit", 
		text => "Out of credits",
		status => 0,
		},
	"AQSMS-OK" => { 
		#text => "The message was queued on our system successfully",
		text => "OK",
		status => 1,
		},
	"AQSMS-CREDIT" => {
		#text is filled out in credit sub
		status => 1,
		},
	"AQSMS-NOMSG" => { 
		text => "No message or no destination number were supplied", 
		status => 0,
		},
	"AQSMS-INVALID_DESTINATION" => { 
		text => "Invalid destination", 
		status => 0,
		},
);

sub last_response_text { shift->{last_response_text} }


# private implementation methods follow - you are advised not to call these
# directly, as their behaviour or even very existence could change in future
# versions.

sub _check_aql_response_code {
	my ($self, $res) = @_;
	my $r = $self->{last_response} = $res->content;
    # Strip everything after initial alphanumerics and hyphen:
	$r =~ s/^([\w\-]+).*/$1/;
	if (exists $lookup{$r}) {
		$self->{last_response_text} = $lookup{$r}->{text};
		$self->{last_status} = $lookup{$r}->{status};
	} else {
		$self->{last_response_text} = "$UNRECOGNISED_RESPONSE: $r";
		$self->{last_status} = 0;
	}
	unless ($self->last_status) {
		$self->{last_error} = $self->{last_response_text};
	}
}



# given an arrayref of possible servers, an URL and a hashref of POST data,
# makes a POST request to each server in turn, stopping as soon as a successful
# response is received and returning the LWP response object.
sub _do_post {

    my ($self, $servers, $url, $postdata) = @_;
    
    if (ref $servers ne 'ARRAY') {
        die "_do_post expects an arrayref of servers to try";
    }
    
    if (ref $postdata ne 'HASH') {
        die "_do_post expects a hashref of post data";
    }
    
    if (!$url || ref $url) {
        die "_do_post expects an URL";
    }
    
    $url =~ s{^/}{};
    
    for my $server (sort { (-1,1)[rand 2] } @{$servers} ) {
        my $response = $self->{ua}->post(
            "http://$server/$url", $postdata);
            
        if ($response->is_success) {
            return $response;
        }
    }
    
    # if we get here, none of the servers we asked responded:
    return;
}


# fix up the number
sub _canonical_number {

    my ($self, $num) = @_;
    
    $num =~ s/[^0-9+]//;
    if (!$num) { return undef; }
    $num =~ s/^0/+44/;
    
    return $num;
}


sub _set_no_valid_response {
    my $self = shift;
    $self->{last_error} = $NO_RESPONSES;
    $self->{last_status} = 0;
}


1;
__END__


=back


=head1 SEE ALSO

http://www.aql.com/


=head1 AUTHOR

David Precious, E<lt>davidp@preshweb.co.ukE<gt>

All bug reports, feature requests, patches etc welcome.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=head1 THANKS

 - to Adam Beaumount and the AQL team for their assistance
 - to Ton Voon at Altinity (http://www.altinity.com/) for contributing
   several improvements

=cut
