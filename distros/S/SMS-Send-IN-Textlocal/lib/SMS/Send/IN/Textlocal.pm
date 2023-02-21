package SMS::Send::IN::Textlocal;
 
# ABSTRACT: SMS::Send driver to send messages via Textlocal (India) SMS Gateway ( https://api.textlocal.in/send/ )
 
use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use URI::Escape;
use JSON;
 
use base 'SMS::Send::Driver';
 
our $VERSION = '1.00'; # VERSION
our $AUTHORITY = 'cpan:INDRADG'; # AUTHORITY
 
sub new {
    my ( $class, %args ) = @_;
 
    # check we have the necessary credentials parameters
    die "SenderID / DLT Header needs to be passsed as  'sender'" unless ( $args{_login}  );
    die "Textlocal API key needs to be passed as 'password'" unless ( $args{_password} );
 
    # build the object
    my $self = bless {
        _endpoint  => 'https://api.textlocal.in/send/',
        _debug     => 0,
        %args
    }, $class;
 
    # get an LWP user agent ready
    # FIXME - bypassing SSL cert check due to NIC's cert chain borkage
    $self->{ua} = LWP::UserAgent->new;
    #$self->{ua}->ssl_opts(
    #    SSL_verify_mode => 0, 
    #    verify_hostname => 0,
    #);
     
    return $self;
}
 
sub _send_method {
    my ( $self, @args ) = @_;
 
    my @params;
    while (@args) {
        my $key = shift @args;
        my $val = shift @args;
        push( @params, join( '=', uri_escape($key), uri_escape($val) ) );
        print STDERR ">>>   Arg $key = $val\n" if ( $self->{_debug} );
    }
    my $url = join( '?', $self->{_endpoint}, join( '&', @params ) );
    print STDERR ">>>   GET $url\n" if ( $self->{_debug} );
 
    my $res = $self->{ua}->get($url);
 
    my $errorbroker = $self->_ERRORHANDLER ( $res );
 
    if ( $errorbroker ) {
        print STDERR "<<<   Message sent successfully\n";
        print STDERR "<<<   SMS gateway response : $res->{_content}\n" if ( $self->{_debug} );
        return 1;
    } else {
        print STDERR "<<<   Message send failed\n";
        print STDERR "<<<   SMS gateway response : $res->{_content}\n";
        return;
    }
}
 
sub send_sms {
 
    my ( $self, %args ) = @_;
  
    # check for message for 160 char limit
    my $text = $self->_MESSAGETEXT ( $args{text} );
     
    # check destination number for well-formedness under NNP 2003 schema
    my $to = $self->_TO ( $args{to} );
 
    $self->_send_method(
        sender    => $self->{_login},
        apikey    => $self->{_password},
        numbers   => $args{to},
        message   => $args{text},
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
 
  # strip out any NaN characters
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
            $dest = $countrycode . $dest;       #bring it up to 91XXXXXXXXXX
        }
 
        # check for 9,8,7,6 series numbering under NNP 2003
        # see https://en.wikipedia.org/wiki/Mobile_telephone_numbering_in_India
        #
        $checkseries = substr $dest, 2, 1;
        die "Invalid phone number as per National Numbering Plan 2003" unless ( $checkseries =~ /[9|8|7|6]/ ); 
  } else {
        die "Invalid phone number format";
  }
  return $dest;
}
 
sub _ERRORHANDLER {
  my ( $self, $res ) = @_;
 
  # check status for success or failure
  
  my $json = decode_json $res->content;

  if ( $json->{'status'} eq 'failure' ) {
      return;
  } else {
      return 1;
  } 
}
 
1;
 
__END__
 
=pod
 
=head1 NAME
 
SMS::Send::IN::Textlocal - Regional context SMS::Send driver to send messages via Textlocal's India service ( https://api.textlocal.in/send/ )
 
=head1 VERSION
 
version 1.00
 
=head1 SYNOPSIS
 
  use SMS::Send;
 
  # Create a sender
  my $sender = SMS::Send->new(
    'IN::Textlocal',
    _login           => 'senderid',          # use actual DLT registered header / sender id 
    _password        => 'apikey',            # use actual Textlocal API key
  );
  # Send a message
  my $sent = $sender->send_sms(
      text => 'This is an example message',  # use actual DLT approved content template
      to   => '91XXXXXXXXX',                 # use actual 10 digit mobile number in place of 'XXXXXXXXXX'
  );
  if ($sent) {
  print "Message send OK\n";
  }
  else {
  print "Failed to send message\n";
   
 
=head1 DESCRIPTION
 
An Indian regional context driver for SMS::Send to send SMS text messages via 
Textlocal's SMS Gateway in India - L<https://api.textlocal.in/send/> with 100% 
compliance to Telecom Regulatory Authority of India's (TRAI) TCCCPR 2018 norms 
which are accessible at L<https://trai.gov.in/sites/default/files/RegulationUcc19072018.pdf>
 
This is not intended to be used directly, but instead called by SMS::Send (see
synopsis above for a basic illustration, and see SMS::Send's documentation for
further information).
 
The driver uses the Textlocal's HTTPS API mechanism for SMS.  This is documented 
at L<https://api.textlocal.in/docs/>.
 
=head1 METHODS
 
=head2 new
 
Constructor, takes argument pairs passed by SMS::Send, returns an
SMS::Send::IN::Textlocal object.  See usage synopsis for example, and see 
SMS::Send documentation for further info on using SMS::Send drivers.
 
Mandatory arguments include:-
 
=over 4
 
=item _login
 
The DLT approved sender id / header allotted to the user institution
 
=item _password
 
The Textlocal API key for the Textlocal user account
  
=back
 
Additional arguments that may be passed include:-
 
=over 4
 
=item _endpoint
 
The HTTPS API endpoint. Defaults to C<https://api.textlocal.in/send/>
 
=item _debug
 
Whether debugging information is output or not.
 
=back
 
 
=head2 send_sms
 
Send the message - see SMS::Send for details. It requires two additional parameters to 
function with the Textlocal SMS gateway in India:
 
=over 4
 
=item "text"
 
The DLT approved service implicit content template. The driver restricts it to 160
characters which forms the message body.
 
=item "to"
 
Destination mobile phone number in India. Numbered as per NNP 2003 i.e. 91XXYYYZZZZZ.
 
 
=back
 
 
=head1 MISCELLANEOUS
 
=head2 Recipient phone number checks
 
Additional checks have been placed into the code for ensuring compliance with 
Indian National Numbering Plan 2003 (and its subsequent amendments). This measure 
is expected to prevent user generated errors due to improperly formatted or 
invalid mobile numbers, as noted below:
 
=over 4
 
=item Example 1 : "819XXXXYYYYY" 
 
81 is an invalid country code. As an India specific driver, the country code must be 91.
 
=item Example 2 : "9XXXXYYYYY"
 
=item Example 3 : "8XXXXYYYYY"
 
=item Example 4 : "7XXXXYYYYY"
 
=item Example 5 : "6XXXXYYYYY"
 
As per National Numbering Plan 2003, cell phone numbers (GSM, CDMA, 4G, LTE) have to 
start with 9XXXX / 8XXXX / 7XXXX / 6XXXX series (access code + operator identifier). 
A phone number that does not fit this template will be rejected by the driver.
 
=item Example 6 : "12345678"
 
=item Example 7 : "12345678901234"
 
A phone number that is less than 10-digits long or over 12-digits long (including 
country code prefix) will be rejected as invalid input as per NNP 2003. 
 
=item Example 8 : "+91 9XXXX YYYYY"
 
=item Example 9 : "+91-9XXXX-YYYYY"
 
=item Example 10 : "+919XXXXYYYYY"
 
=item Example 11 : "09XXXXYYYYY"
 
Phone numbers formatted as above, when input to the driver will be handled 
as "919XXXXYYYYY" by the driver.
 
=back
 
=head2 Error Codes
 
The following error code are returned by the NIC HTTPS API:
 
=over 4

=item -   3 : Invalid number.
=item -   4 : No recipients specified.
=item -   5 : No message content.
=item -   6 : Message too long.
=item -   7 : Insufficient credits.
=item -   8 : Invalid schedule date.
=item -   9 : Schedule date is in the past.
=item -  10 : Invalid group ID.
=item -  11 : Selected group is empty.
=item -  32 : Invalid number format.
=item -  33 : You have supplied too many numbers.
=item -  34 : You have supplied both a group ID and a set of numbers.
=item -  43 : Invalid sender name.
=item -  44 : No sender name specified.
=item -  51 : No valid numbers specified.
=item -  80 : Invalid Template. The message given didn't match any approved templates on your account.
=item - 191 : Schedule time is outside that allowed.
=item - 192 : You cannot send message at this time.

=back
 
In the driver we only check if the status code is B<success> or not in the response 
sent back by the SMS Gateway. In case of B<failure> we send the output to STDERR.
 
 
=head1 INSTALLATION
 
See L<https://perldoc.perl.org/perlmodinstall> for information and options 
on installing Perl modules.
 
 
=head1 BUGS AND LIMITATIONS
 
You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=SMS-Send-IN-Textlocal>.
 
=head1 AVAILABILITY
 
The project homepage is L<https://metacpan.org/release/SMS-Send-IN-Textlocal>.
 
The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/SMS::Send::IN::Textlocal/>.
 
Alternatively, you can also visit the GitHub repository for this driver at
L<https://github.com/l2c2technologies/sms-send-in-Textlocal>
 
 
=head1 ACKNOWLEDGEMENT
 
A big thanks to authors of pre-existing regional send driver authors, my K-C 
colleagues whose work on the drivers were a big inspiration. Also, a big shoutout 
to my ex-colleague Teertha Chatterjee who assisted in testing the code in 
production when it was being developed.
 
 
=head1 AUTHOR
 
Indranil Das Gupta E<lt>indradg@l2c2.co.inE<gt> (on behalf of L2C2 Technologies).
 
 
=head1 COPYRIGHT AND LICENSE
 
Copyright (C) 2023 L2C2 Technologies
 
This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language system itself, or at your option, any 
later version of Perl 5 you may have available.
 
This software comes with no warranty of any kind, including but not limited to 
the implied warranty of merchantability.
 
Your use of this software may result in charges against / use of available 
credits on your NIC SMS Service account. Please use this software carefully 
keeping a close eye on your usage and/or billing, The author takes no 
responsibility for any such charges accrued.
 
Document published by L2C2 Technologies [ https://www.l2c2.co.in ]
 
=cut
