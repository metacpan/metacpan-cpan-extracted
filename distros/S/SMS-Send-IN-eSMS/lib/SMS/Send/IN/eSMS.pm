package SMS::Send::IN::eSMS;

# ABSTRACT: SMS::Send driver to send messages via eSMS ( http://api.esms.kerala.gov.in )

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use URI::Escape;

use base 'SMS::Send::Driver';

our $VERSION = '0.01'; # VERSION
our $AUTHORITY = 'cpan:INDRADG'; # AUTHORITY

# setup error code lookup list for eSMS
our %eSMS_error_codes = ( "401", "Credentials Error, may be invalid username or password",
   "402", "1 message submitted successfully",
   "403", "Credits not available",
   "404", "Internal Database Error",
   "405", "Internal Networking Error",
   "406", "Invalid or Duplicate numbers",
   "407", "Network Error on SMSC",
   "408", "Network Error on SMSC",
   "409", "SMSC response timed out, message will be submitted",
   "410", "Internal Limit Exceeded, Contact support",
   "411", "Sender ID not approved.",
   "412", "Sender ID not approved.",   
   "413", "Suspect Spam, we do not accept these messages.",
   "414", "Rejected by varous reasons by the operator such as DND, SPAM etc" );
   
sub new {
    my ( $class, %args ) = @_;

    # check we have an username and password
    die "Username needs to be passed as 'username'" unless ( $args{_login}  );
    die "Password needs to be passed as 'password'" unless ( $args{_password} );
    die "SenderID needs to be passsed as 'senderid'" unless ( $args{_senderid} );

    # build the object
    my $self = bless {
        _endpoint  => 'http://api.esms.kerala.gov.in/fastclient/SMSclient.php',
        _debug     => 0,
        %args
    }, $class;

    # get an LWP user agent ready
    $self->{ua} = LWP::UserAgent->new;
    
    return $self;
}

sub _send_method {
    my ( $self, @args ) = @_;

    my @params;
    while (@args) {
        my $key = shift @args;
        my $val = shift @args;
        push( @params, join( '=', uri_escape($key), uri_escape($val) ) );
        print STDERR ">>>     Arg $key = $val\n" if ( $self->{_debug} );
    }
    my $url = join( '?', $self->{_endpoint}, join( '&', @params ) );
    print STDERR ">>> GET $url\n" if ( $self->{_debug} );

    my $res = $self->{ua}->get($url);

    printf STDERR "<<< Status:  %s\n<<< Content: %s\n", $res->code, $res->content if ( $self->{_debug} );

    my $errorbroker = $self->_ERRORHANDLER ( $res, %eSMS_error_codes );

    die $res->status_line unless ( $res->is_success );

    return $res;
}

sub send_sms {

    my ( $self, %args ) = @_;
    
    # check for message for 160 char limit
    my $text = $self->_MESSAGETEXT (  $args{text} );
    
    # check destination number for well-formedness under NNP 2003 schema
    my $to = $self->_TO ( $args{to} );

    $self->_send_method(
        username      => $self->{_login},
        password      => $self->{_password},
        numbers       => $args{to},
        message       => $args{text},
		senderid      => $self->{_senderid},
    );
}

# -----------------------------------------------------
# internal sanitization routines
# -----------------------------------------------------

sub _MESSAGETEXT {
  my ( $self, $text ) = @_;
  use bytes;
  die "Message length over limit. Max length is 160 characters" unless ( length($text) <= 160 ); 
} # check for 160 char length of message text

# As per National Numbering Plan 2003, Indian mobile phone numbers have to be in
# [9|8|7]XXXXXXXXX format. So we need to sanitize our input. The driver expects
# number string in 91XXXXXXXXXX format

sub _TO {
  my ( $self, $dest ) = @_;

  my $checkseries;
  my $countrycode;

  # strip out NaN characters
  $dest =~ s/[^\d]//g;

  # strip leading zero as some have the habit of inputing numbers as 0XXXXXXXXXX
  $dest =~ s/^0+//g;

  # check destination number length and format for well-formedness and fix common issues.
  if ( length($dest) == 12 or length($dest) == 10 ) {
  	if ( length($dest) == 12 ) {
	    $countrycode = substr $dest, 0, 2;
	    die "Country code incorrect, needs to be 91 for India" unless ( $countrycode eq '91' ); 
        }
	if ( length($dest) == 10 ) {
	    $countrycode = "91";
	    $dest = $countrycode . $dest;	#bring it up to 91XXXXXXXXXX
	}

	# check for 9,8,7 series numbering under NNP 2003
        $checkseries = substr $dest, 2, 1;
        die "Invalid phone number as per National Numbering Plan 2003" unless ( $checkseries =~ /[9|8|7]/ ); 
  } else {
        die "Invalid phone number format";
  }
  return $dest;
}

sub _ERRORHANDLER {
  my ( $self, $res, %uecodes ) = @_;

  my $res_content = $res->content; 

  # check for unique MID (message ID) signifying a successful transaction

  if ( $res_content =~ /^[0-9]+$/  and  length( $res_content ) == 19 ) {
      return "Successfully transmitted with MID $res_content\n";
  } else {
      my $ecode = substr $res_content, 0, 5;
      if ( $uecodes{$ecode} ) {
	die "eSMS error $ecode : $uecodes{$ecode}";
      } 
  } 
}

1;

__END__

=pod

=for stopwords ACKNOWLEDGEMENTS CPAN Centre Unicode homepage

=head1 NAME

SMS::Send::IN::eSMS - Regional context SMS::Send driver to send messages via eSMS Kerala gateway ( http://api.esms.kerala.gov.in )

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use SMS::Send;

  # Create a sender
  my $sender = SMS::Send->new(
      'IN::eSMS',
      _login    => 'username',
      _password => 'password',
      _senderid => 'senderid',
  );

  # Send a message
  my $sent = $sender->send_sms(
      text => 'This is a test message',
      to   => '919876012345',
  );

  if ($sent) {
      print "Message send OK\n";
  }
  else {
      print "Failed to send message\n";
  }

=head1 DESCRIPTION

An Indian regional context driver for SMS::Send to send SMS text messages via 
eSMS Kerala gateway in India - L<http://api.esms.kerala.gov.in>

This is not intended to be used directly, but instead called by SMS::Send (see
synopsis above for a basic illustration, and see SMS::Send's documentation for
further information).

The driver uses the eSMS's HTTP GET API mechanism.  This is documented in the 
Developer documentation available to customers of the service.

=head1 METHODS

=head2 new

Constructor, takes argument pairs passed by SMS::Send, returns an
SMS::Send::IN::eSMS object.  See usage synopsis for example, and see SMS::Send
documentation for further info on using SMS::Send drivers.

Additional arguments that may be passed include:-

=over 4

=item _endpoint

The HTTP API endpoint.  Defaults to
C<http://api.esms.kerala.gov.in/fastclient/SMSclientdr.php>

=item _debug

Whether debugging information is output or not.

=back

=head2 send_sms

Send the message - see SMS::Send for details. Briefly it requires two principal parameters to function:

=over 4

=item "text"

Used to supply the 160 character message body.

=item "to"

Destination mobile phone number in India. Numbered as per NNP 2003 i.e. 91XXYYYZZZZZ.

=back

=head1 MISCELLANEOUS

=head2 Recipient phone number checks

Additional checks have been placed into the code for ensuring compliance with Indian
National Numbering Plan 2003 (and its subsequent amendments). This measure is expected
to prevent user generated errors due to improperly formatted or invalid mobile numbers,
as noted below:

=over 4

=item Example 1 : "819XXXXYYYYY" 

81 is an invalid country code. As an India specific driver, the country code must be 91.

=item Example 2 : "9XXXXYYYYY"

=item Example 3 : "8XXXXYYYYY"

=item Example 4 : "7XXXXYYYYY"

As per National Numbering Plan 2003, cell phone numbers (both GSM and CDMA) have to start
with 9XXXX / 8XXXX / 7XXXX series (access code + operator identifier). A phone number that
does not fit this template will be rejected by the driver.

=item Example 5 : "12345678"

=item Example 6 : "12345678901234"

A phone number that is less than 10-digits long or over 12-digits long (including country
code prefix) will be rejected as invalid input as per NNP 2003. 

=item Example 7 : "+91 9XXXX YYYYY"

=item Example 8 : "+91-9XXXX-YYYYY"

=item Example 9 : "+919XXXXYYYYY"

=item Example 10 : "09XXXXYYYYY"

Phone numbers formatted as above, when input to the driver will be handled as "919XXXXYYYYY"

=back

=head2 Error Codes

The following error codes are returned by the eSMS HTTP API:

=over 4

=item 401 - Credentials Error, may be invalid username or password

=item 402 - 1 message submitted successfully

=item 403 - Credits not available

=item 404 - Internal Database Error

=item 405 - Internal Networking Error

=item 406 - Invalid or Duplicate numbers

=item 407 - Network Error on SMSC

=item 408 - Network Error on SMSC

=item 409 - SMSC response timed out, message will be submitted

=item 410 - Internal Limit Exceeded, Contact support

=item 411 - Sender ID not approved.

=item 412 - Sender ID not approved.

=item 413 - Suspect Spam, we do not accept these messages.

=item 414 - Rejected by varous reasons by the operator such as DND, SPAM etc

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=SMS-Send-IN-eSMS>.

=head1 AVAILABILITY

The project homepage is L<https://metacpan.org/release/SMS-Send-IN-eSMS>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/SMS::Send::IN::eSMS/>.

=head1 ACKNOWLEDGEMENT

Driver development cost was sponsored by State Librarian, State Central Library,
Trivandrum, Kerala. Also noted thankfully the facilitation done by KELTRON and
other individuals associated with the project who made it possible to write and
release this driver as Free Software.

Severel existing drivers both international and regional, were inspiration and
source for liberal copying.

=head1 AUTHOR

Indranil Das Gupta E<lt>indradg@l2c2.co.inE<gt> (for L2C2 Technologies).

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Indranil Das Gupta.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself, or at your option, any
later version of Perl 5 you may have available.

This software comes with no warranty of any kind, including but not limited to
the implied warranty of merchantability.

Your use of this software may result in charges against / use of available credits
on your eSMS account. Please use this software carefully keeping a close eye on 
your usage and/or billing, The author takes no responsibility for any such charges
accrued.

Document published by L2C2 Technologies [ L<http://www.l2c2.co.in> ]

=cut
