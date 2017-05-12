# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('Net::ESMTP') };


my $fail = 0;
foreach my $constname (qw(
  By_NOTSET By_NOTIFY By_RETURN
  E8bitmime_NOTSET E8bitmime_7BIT E8bitmime_8BITMIME E8bitmime_BINARYMIME
  Hdr_OVERRIDE Hdr_PROHIBIT
  Notify_NOTSET Notify_NEVER Notify_SUCCESS Notify_FAILURE Notify_DELAY
  Ret_NOTSET Ret_FULL Ret_HDRS
  SMTP_EV_CONNECT SMTP_EV_MAILSTATUS SMTP_EV_RCPTSTATUS SMTP_EV_MESSAGEDATA
  SMTP_EV_MESSAGESENT SMTP_EV_DISCONNECT SMTP_EV_ETRNSTATUS SMTP_EV_EXTNA_DSN
  SMTP_EV_EXTNA_8BITMIME SMTP_EV_EXTNA_STARTTLS SMTP_EV_EXTNA_ETRN SMTP_EV_EXTNA_CHUNKING
  SMTP_EV_EXTNA_BINARYMIME SMTP_EV_DELIVERBY_EXPIRED SMTP_EV_WEAK_CIPHER SMTP_EV_STARTTLS_OK
  SMTP_EV_INVALID_PEER_CERTIFICATE SMTP_EV_NO_PEER_CERTIFICATE SMTP_EV_WRONG_PEER_CERTIFICATE
  Starttls_DISABLED Starttls_ENABLED Starttls_REQUIRED
  Timeout_GREETING Timeout_ENVELOPE Timeout_DATA Timeout_TRANSFER Timeout_DATA2
	SMTP_CB_HEADERS SMTP_CB_READING SMTP_CB_WRITING
	SMTP_ERR_DROPPED_CONNECTION SMTP_ERR_EAI_ADDRFAMILY SMTP_ERR_EAI_AGAIN
	SMTP_ERR_EAI_BADFLAGS SMTP_ERR_EAI_FAIL SMTP_ERR_EAI_FAMILY
	SMTP_ERR_EAI_MEMORY SMTP_ERR_EAI_NODATA SMTP_ERR_EAI_NONAME
	SMTP_ERR_EAI_SERVICE SMTP_ERR_EAI_SOCKTYPE
	SMTP_ERR_EXTENSION_NOT_AVAILABLE SMTP_ERR_HOST_NOT_FOUND SMTP_ERR_INVAL
	SMTP_ERR_INVALID_RESPONSE_STATUS SMTP_ERR_INVALID_RESPONSE_SYNTAX
	SMTP_ERR_NOTHING_TO_DO SMTP_ERR_NO_ADDRESS SMTP_ERR_NO_RECOVERY
	SMTP_ERR_STATUS_MISMATCH SMTP_ERR_TRY_AGAIN
	SMTP_ERR_UNTERMINATED_RESPONSE Timeout_OVERRIDE_RFC2822_MINIMUM)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Net::ESMTP macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok('Net::ESMTP', 'smtp_version');

my $session = new Net::ESMTP::Session ();
isa_ok ($session, 'Net::ESMTP::Session');

my $message = $session->add_message();
isa_ok ($message, 'Net::ESMTP::Message');

my $file = 'test.eml';
open FH, "<$file" || die "Can not open test.eml: $!";
cmp_ok ($message->set_messagecb (\&readlinefp, \*FH), '==', 1, 'set_messagecb');

my $recipient = $message->add_recipient ('test-nonexists@example.com');
isa_ok ($recipient, 'Net::ESMTP::Recipient');

my $notify = Notify_NOTSET;
cmp_ok($recipient->dsn_set_notify ($notify),'==',1,'dsn_set_notify');

undef $session, $message, $recipient;
close(FH);

sub readlinefp {
    my ($len, $fh) = @_;
    if (!defined($len)) {
	seek ($fh, 0, 0);
	return 0;
    }
    my $line;
    if (!($line = <$fh>)) {
	return undef;
    }
    chomp($line);
    $line .= "\r\n";
    return $line;
}

