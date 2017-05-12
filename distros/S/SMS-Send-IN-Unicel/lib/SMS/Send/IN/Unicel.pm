package SMS::Send::IN::Unicel;

# ABSTRACT: SMS::Send driver to send messages via Unicel (http://unicel.in/)

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use URI::Escape;

use base 'SMS::Send::Driver';

our $VERSION = '0.01'; # VERSION
our $AUTHORITY = 'cpan:INDRADG'; # AUTHORITY

# setup error code lookup list for Unicel
our %unicel_error_codes = ( "0x200", "Invalid Username or Password",
   "0x201", "Account suspended due to one of several defined reasons",
   "0x202", "Invalid Source Address/Sender ID. As per GSM standard, the sender ID should be within 11 characters",
   "0x203", "Message length exceeded (more than 160 characters) if concat is set to 0 Message",
   "0x204", "Message length exceeded (more than 459 characters) in concat is set to 1",
   "0x205", "DRL URL is not set",
   "0x206", "Only the subscribed service type can be accessed - make sure of the service type you are trying to connect with",
   "0x207", "Invalid Source IP - kindly check if the IP is responding",
   "0x208", "Account deactivated/expired",
   "0x209", "Invalid message length (less than 160 characters) if concat is set to 1",
   "0x210", "Invalid Parameter values",
   "0x211", "Invalid Message Length (more than 280 characters)",
   "0x212", "Invalid Message Length",
   "0x213", "Invalid Destination Number" );

sub new {
    my ( $class, %args ) = @_;

    # check we have an username and password
    die "Username needs to be passed as 'uname'" unless ( $args{_login}  );
    die "Password needs to be passed as 'pass'" unless ( $args{_password} );

    # build the object
    my $self = bless {
        _endpoint  => 'https://unicel.in/SendSMS/sendmsg.php',
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

    my $errorbroker = $self->_ERRORHANDLER ( $res, %unicel_error_codes );

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
        uname      => $self->{_login},
        pass       => $self->{_password},
        dest       => $args{to},
        msg        => $args{text},
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
	die "Unicel error $ecode : $uecodes{$ecode}";
      } 
  } 
}

1;

__END__

=pod

=for stopwords ACKNOWLEDGEMENTS CPAN Centre Unicode homepage

=head1 NAME

SMS::Send::IN::Unicel - Regional context SMS::Send driver to send messages via Unicel Technologies (http://unicel.in/)

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use SMS::Send;

  # Create a sender
  my $sender = SMS::Send->new(
      'IN::Unicel',
      _login    => 'username',
      _password => 'password',
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
Unicel Technologies in India - L<http://unicel.in/>

This is not intended to be used directly, but instead called by SMS::Send (see
synopsis above for a basic illustration, and see SMS::Send's documentation for
further information).

The driver uses the Unicel's HTTP GET API mechanism.  This is documented in the 
Developer documentation available to paying customers of the service.

=head1 METHODS

=head2 new

Constructor, takes argument pairs passed by SMS::Send, returns an
SMS::Send::IN::Unicel object.  See usage synopsis for example, and see SMS::Send
documentation for further info on using SMS::Send drivers.

Additional arguments that may be passed include:-

=over 4

=item _endpoint

The HTTP API endpoint.  Defaults to
C<https://unicel.in/SendSMS/sendmsg.php>

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

Additional checks have been placed into the code for ensuring compliance with Indian National Numbering Plan 2003 (and its subsequent amendments). This measure is expected to prevent user generated errors due to improperly formatted or invalid mobile numbers, as noted below:

=over 4

=item Example 1 : "819XXXXYYYYY" 

81 is an invalid country code. As an India specific driver, the country code must be 91.

=item Example 2 : "9XXXXYYYYY"

=item Example 3 : "8XXXXYYYYY"

=item Example 4 : "7XXXXYYYYY"

As per National Numbering Plan 2003, cell phone numbers (both GSM and CDMA) have to start with 9XXXX / 8XXXX / 7XXXX series (access code + operator identifier). A phone number that does not fit this template will be rejected by the driver.

=item Example 5 : "12345678"

=item Example 6 : "12345678901234"

A phone number that is less than 10-digits long or over 12-digits long (including country code prefix) will be rejected as invalid input as per NNP 2003. 

=item Example 7 : "+91 9XXXX YYYYY"

=item Example 8 : "+91-9XXXX-YYYYY"

=item Example 9 : "+919XXXXYYYYY"

=item Example 10 : "09XXXXYYYYY"

Phone numbers formatted as above, when input to the driver will be handled as "919XXXXYYYYY"

=back

=head2 Error Codes

The following error codes are returned by the Unicel HTTP API:

=over 4

=item 0x201 - Account suspended due to one of several defined reasons.

=item 0x202 - Invalid Source Address/Sender ID.

=item 0x203 - Message length exceeded (more than 160 characters) if concat is set to 0 Message.

=item 0x204 - Message length exceeded (more than 459 characters) in concat is set to 1.

=item 0x205 - DRL URL is not set.

=item 0x206 - Only the subscribed service type can be accessed - make sure of the service type you are trying to connect with.

=item 0x207 - Invalid Source IP - kindly check if the IP is responding.

=item 0x208 - Account deactivated/expired.

=item 0x209 - Invalid message length (less than 160 characters) if concat is set to 1.

=item 0x210 - Invalid Parameter values.

=item 0x211 - Invalid Message Length (more than 280 characters).

=item 0x212 - Invalid Message Length.

=item 0x213 - Invalid Destination Number.

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=SMS-Send-IN-Unicel>.

=head1 AVAILABILITY

The project homepage is L<https://metacpan.org/release/SMS-Send-IN-Unicel>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/SMS::Send::IN::Unicel/>.

=head1 ACKNOWLEDGEMENT

Severel existing drivers both international and regional, were inspiration and
source for liberal copying.

=head1 AUTHOR

Indranil Das Gupta E<lt>indradg@l2c2.co.inE<gt> (on behalf of L2C2 Technologies).

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Indranil Das Gupta.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself, or at your option, any later version of Perl 5 you may have available.

This software comes with no warranty of any kind, including but not limited to the implied warranty of merchantability.

Your use of this software may result in charges against / use of available credits on your Unicel account. Please use this software carefully keeping a close eye on your usage and/or billing, The author takes no responsibility for any such charges accrued.

Document published by L2C2 Technologies [ http://www.l2c2.co.in ]

=cut
