# $Id: PayflowPro.pm 4712 2016-01-21 15:21:14Z khera $
#
# Copyright 2016 MailerMailer, LLC
#
# Based on documentation found at:
# http://www.pdncommunity.com/pdn/board/message?message.uid=28775
# http://www.pdncommunity.com/pdn/board/message?board.id=payflow&thread.id=1123

package PayflowPro;
use strict;

=pod

=head1 NAME

PayflowPro - Library for accessing PayPal's Payflow Pro HTTP interface

=head1 SYNOPSIS

  use PayflowPro qw(pfpro);
  my $data = {
    USER=>'MyUserId',
    VENDOR=>'MyVendorId',
    PARTNER=>'MyPartnerId',
    PWD=>'MyPassword',

    AMT=> '42.24',
    TAXAMT=>'0.00',      # no tax charged, but specifying it lowers cost
    INVNUM=>$$,
    DESC=>"Test invoice $$",
    COMMENT1=>"Comment 1 $$",
    COMMENT2=>"Comment 2 $$",
    CUSTCODE=>$$ . 'a' . $$,

    TRXTYPE=>'S',			# sale
    TENDER=>'C',			# credit card

    # Commercial Card additional info
    PONUM=>$$.'-'.$$,
    SHIPTOZIP=>'20850', # for AmEx Level 2
    DESC4=>'FRT0.00',	# for AmEx Level 2

    # verisign tracking info
    STREET => '123 AnyStreet',
    CITY => 'Anytown',
    COUNTRY => 'us',
    FIRSTNAME => 'Firsty',
    LASTNAME => 'Lasty',
    STATE => 'md',
    ZIP => '20850',

    ACCT => '5555555555554444',
    EXPDATE => '1009',
    CVV2 => '123',
  };

  my $res = pfpro($data);

  if ($res->{RESULT} == 0) {
    print "Woohooo!  We charged the card!\n";
  }

=head1 DESCRIPTION

Interface to HTTP gateway for PayPal's Payflow Pro service.  Implements
the pfpro() function to simplify replacing the old PFProAPI perl module.

Methods implemented are:

=cut

use base qw(Exporter);
@PayflowPro::EXPORT_OK = qw(pfpro pftestmode pfdebug);

use LWP::UserAgent;
use HTTP::Request;
use Config;

use constant NUMRETRIES => 3;	# number of times to retry HTTP timeout/err
use vars qw($VERSION);

$VERSION = sprintf "%d", q$Revision: 4712 $ =~ /(\d+)/;
my $agent = "MailerMailer PFPro";

my ($pfprohost,$debug);
pftestmode(0);			# set "live" mode as default.

our $timeout = 30;

my $ua = new LWP::UserAgent;
$ua->agent("$agent/$VERSION");

=pod

=head2 pftestmode($testmode)

Set test mode on or off.  Test mode means it uses the testing server
rather than the live one.  Default mode is live (C<$testmode> == 0).

Returns true.

=cut

sub pftestmode {
  my $testmode = shift;

  $pfprohost = $testmode ?
    'pilot-payflowpro.paypal.com' :
    'payflowpro.paypal.com';

  return 1;
}

=pod

=head2 pfdebug($mode)

Set debug mode on or off.  Turns on some warn statements to track progress
of the request.  Default mode is off (C<$mode> == 0).

Returns current setting.

=cut

sub pfdebug {
  my $mode = shift;

  $ENV{'HTTPS_DEBUG'} = $mode;	# assumes Crypt::SSLeay as the SSL engine
  return $debug = $mode;
}

=pod

=head2 pfpro($data)

Process request as per hash ref C<$data>.  See PFPro API docs on
name/value pairs to pass in.  All we do here is convert them into an
HTTP request, then convert the response back into a hash and return
the reference to it.  This emulates the pfpro() function in the
original API.

Additionally, we honor a C<TIMEOUT> value which specifies the number
of seconds to wait for a response from the server. The default is 30
seconds.  Normally for production you should not need to alter this
value.  The test servers are slower so may need larger timeout. The
minimum value that PayPal will accept is 5 seconds.

It uses the time and the C<INVNUM> (Invoice Number) field of input to
generate the unique request ID, so don't try to process the same
INVNUM more than once per second.  C<INVNUM> is a required datum to be
passed into this function.  Bad things happen if you don't.

Upon communications failure, it fakes up a response message with
C<RESULT> = -1.  Internally, the library tries several times to process
the transaction if there are network problems before returning this
failure mode.

To validate the SSL certificate, you need a ca-bundle file with a list
of valid certificate signers.  Then set the environment variable
HTTPS_CA_FILE to point to that file.  This assumes you are using the
C<Crypt::SSLeay> SSL driver for LWP (should be the default).  In your code,
add some lines like this:

 # CA cert peer verification
 $ENV{HTTPS_CA_FILE} = '/path/to/ca-bundle.crt';

It is likely to be in F</etc/ssl> or F</usr/local/etc/ssl> or
F</usr/local/certs> depending on your OS version.  The script
F<mk-ca-bundle.pl> included with this module can be used to create the
bundle file based on the current Mozilla certificate data if you don't
already have such a file.  One is also included in the source for this
module, but it may be out of date so it is recommended that you run
the F<mk-ca-bundle.pl> script to ensure you have the latest
information. This program is copied from the CURL project
C<https://github.com/bagder/curl/blob/master/lib/mk-ca-bundle.pl>

If you do not set HTTPS_CA_FILE it will still work, but you don't get
the certificate validation to ensure you're speaking to the authentic
site.  You will also get in the HTTPS response headers

 Client-SSL-Warning: Peer certificate not verified

but you'll only see that if you turn on debugging.

=cut

sub pfpro {
  my $data = shift;

  # for the case of a referenced credit, the INVNUM is not required to be set
  # so use the ORIGID instead.  If that's not set, just use a fixed string
  # to avoid undef warnings.
  my $request_id=substr(time . $data->{TRXTYPE} . ($data->{INVNUM} || $data->{ORIGID} || 'NOID'),0,32);
  utf8::encode($request_id);

  if (defined $data->{TIMEOUT}) {
    $timeout = $data->{TIMEOUT} + 0;
  }

  $ua->timeout($timeout + 1); # one more than timeout in VPS header below

  my $r = HTTP::Request->new(POST => "https://$pfprohost/");
  $r->content_type('text/namevalue');
  $r->header('X-VPS-REQUEST-ID' => $request_id,
	     'X-VPS-CLIENT-TIMEOUT' => $timeout, # timeout in seconds
	     'X-VPS-VIT-INTEGRATION-PRODUCT' => $agent,
	     'X-VPS-VIT-INTEGRATION-VERSION' => $VERSION,
	     'X-VPS-VIT-OS-NAME' => $Config::Config{osname},
	     'X-VPS-VIT-OS-VERSION' => $Config::Config{osvers},
	     'X-VPS-VIT-RUNTIME-VERSION' => $],
	     'Connection' => 'close',
	     'Host' => $pfprohost,
	    );

  # build the body of the request
  while (my ($k,$v) = each %{$data}) {
    utf8::encode($v);
    my $len = length($v);
    $r->add_content($k."[$len]=".$v.'&');
  }
  $r->add_content('VERBOSITY=MEDIUM'); # from example code. unsure what it does

  $r->content_length(length(${$r->content_ref}));

  warn "HTTP Request:\n\n",$r->as_string() if $debug;

  my $retval = {};		# hash of values to return

  my $maxtries = NUMRETRIES;
  my $response;

  # Keep trying the request until we succeed, or fail NUMRETRIES times.
  # Since the REQUEST_ID is the same, we don't ever process
  # the request more than once, but we deal with timout cases:
  # If the request worked and we failed to get the response, we just
  # get the original response back; if it failed to reach PayPal, we
  # just retry it.  NOTE: This does not retry on payflow errors, just
  # when the HTTP protocol has failures/errors such as timeout.
  do {
    warn "Running request, $maxtries left\n" if $debug;
    sleep ((NUMRETRIES - $maxtries) * 30); # delay for a bit between failures
    $response = $ua->request($r);
  } while (--$maxtries and not $response->is_success);

  # Check the outcome of the response
  if ($response->is_success) {
    # parse the return value into the hash and send it back.
    warn "\nHTTP response:\n\n",$response->as_string if $debug;
    my $c = $response->content;
    foreach my $part (split '&',$c) {
      my ($k,$v) = split '=',$part;
      $retval->{$k} = $v;
    }
  } else {
    # some error. fake up the old API's error code so existing code continues
    # to work.  this should just cause a retry on the application.
    warn "HTTP communication error: ".$response->status_line()."\n" if $debug;
    $retval->{RESULT} = -1;
    $retval->{RESPMSG} = 'Failed to connect to host';
  }

  $retval->{'X-VPS-REQUEST-ID'} = $request_id;	# useful for debugging

  return $retval;
}

1;


=pod

=head1 AUTHOR

Vivek Khera <vivek@khera.org>

=head1 LICENSE

This module is Copyright 2007-2016 Khera Communications, Inc.  It is
licensed under the same terms as Perl itself.

=cut
