#-*-perl-*-
print "1..73\n";

use Net::IMAP;

my $host = '/usr/sbin/imapd';

my $testmsg = "From: joe\@example.com
To: bob\@example.com
Subject: an imap test
MIME-Version: 1.0
Content-ID: greeble
Content-Description: snorf

atest
";

my $multipartmsg = "From joe\@example.com
To: bob\@example.com
Sobject: a multipart imap test
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=bork
Content-Disposition: inline
Content-Language: en

--bork

snorfle-foo

--bork
Content-Type: message/rfc822

From: mary\@example.com
To: larry\@example.com
Date: Sat, 28 Aug 1999 21:15:05 -0700

an embedded message

--bork
Content-Type: multipart/alternative; boundary=inner

--inner

inner1

--inner

inner2

--inner--

--bork--
";

my $time = time;

my $testfolder = "net\"xap.$$.$time";

my $imap = new Net::IMAP($host);
my $response;
my $status = undef;		# used in status callback

ok_if(1, defined($imap));

my @capabilities = $imap->capabilities;

my $fetch_resp = undef;
my @search_items = ();

$imap->set_untagged_callback('fetch', \&do_fetch);
$imap->set_untagged_callback('status', \&do_status);
$imap->set_untagged_callback('search', \&do_search);
$imap->set_untagged_callback('list', \&do_list);

ok_if(2, scalar(@capabilities));

ok_if(3, $imap->has_capability('imap4rev1'));

$response = $imap->noop;
ok_if(4, defined($response));
ok_if(5, $response->status eq 'ok');

warn "expect a warning message about an unknown command:\n";

$response = $imap->notacommand('arf');
ok_if(6, !defined($response));

$response = $imap->select($testfolder);
ok_if(7, $response->status eq 'no');

$response = $imap->create($testfolder);
ok_if(8, $response->status eq 'ok');

$response = $imap->append($testfolder, $testmsg);
ok_if(9, $response->status eq 'ok');

$response = $imap->append($testfolder, $testmsg,
			  Date => '28-Aug-1999 15:16:17 -0700');
ok_if(10, $response->status eq 'ok');

$response = $imap->append($testfolder, $testmsg,
			  Date => [$time, '-0700']);
ok_if(11, $response->status eq 'ok');

$response = $imap->append($testfolder, $multipartmsg,
			  Flags => ["\\Draft"]);
ok_if(12, $response->status eq 'ok');

$response = $imap->select($testfolder);
ok_if(13, $response->status eq 'ok');
ok_if(14, $imap->qty_messages == 4);
ok_if(15, $imap->qty_recent == 4);

$response = $imap->copy(1, $testfolder);
ok_if(16, $response->status eq 'ok');

ok_if(17, $imap->qty_messages == 5);

$response = $imap->store('1:4', 'flags', '\\deleted');
ok_if(18, $response->status eq 'ok');

$response = $imap->search('deleted');
ok_if(19, $response->status eq 'ok');
ok_if(20, $#search_items == 3);
ok_if(21, ($#search_items == 3) && ($search_items[0] == 1));

$response = $imap->store(5, 'flags', '\\flagged');
ok_if(22, $response->status eq 'ok');

$response = $imap->fetch(5, qw(rfc822.size internaldate flags
			       envelope bodystructure body.peek[]));
ok_if(23, $response->status eq 'ok');

ok_if(24, $fetch_resp->msgnum == 5);
ok_if(25, scalar($fetch_resp->items) == 6);

my $crlfstring = $testmsg;
$crlfstring =~ s/\n/\r\n/mg;
$msglen = length($crlfstring);

my $n = $fetch_resp->item('rfc822.size');

ok_if(26, defined($n));
ok_if(27, defined($n) && ($n == $msglen));

ok_if(28, defined($fetch_resp->item('internaldate')));

my $flags = $fetch_resp->item('flags');

ok_if(29, defined($flags));
ok_if(30, defined($flags) && $flags->has_flag('\flagged'));

my $envelope = $fetch_resp->item('envelope');

ok_if(31, defined($envelope));

my $subject;
$subject = $envelope->subject if defined($envelope);

ok_if(32, defined($subject));
ok_if(33, defined($subject && ($subject eq 'an imap test')));

my $to;
$to = $envelope->to if defined($envelope);

ok_if(34, scalar(@{$to}) == 1);
ok_if(35, (scalar(@{$to}) == 1) && ($to->[0]->domain eq 'example.com'));
ok_if(36, ((scalar(@{$to}) == 1)
	   && ($to->[0]->as_string eq 'bob@example.com')));

my $bodystructure = $fetch_resp->item('bodystructure');
ok_if(37, defined($bodystructure));
ok_if(38, $bodystructure->type eq 'text');
ok_if(39, $bodystructure->subtype eq 'plain');

ok_if(40, 1);

my $parms = $bodystructure->parameters if defined($bodystructure);
ok_if(41, defined($parms) && (ref($parms) eq 'HASH'));
my $id = $bodystructure->id if defined($bodystructure);
ok_if(42, $id eq 'greeble');
my $description = $bodystructure->description if defined($bodystructure);
ok_if(43, $description eq 'snorf');
my $encoding = $bodystructure->encoding if defined($bodystructure);
ok_if(44, $encoding eq '7bit');
my $size = $bodystructure->size if defined($bodystructure);
ok_if(45, defined($size) && ($size == 7));
my $lines = $bodystructure->lines if defined($bodystructure);
ok_if(46, defined($lines) && ($lines == 1));
ok_if(47, defined($bodystructure) && !defined($bodystructure->envelope));
ok_if(48, defined($bodystructure) && !defined($bodystructure->bodystructure));

my $body = $fetch_resp->item('body[]');

ok_if(49, defined($body));
ok_if(50, defined($body) && ($body eq $testmsg));
#------------------------------------------------------------------------------
$response = $imap->fetch(4, qw(bodystructure));
ok_if(51, $response->status eq 'ok');

$bodystructure = $fetch_resp->item('bodystructure');
ok_if(52, defined($bodystructure));
ok_if(53, defined($bodystructure) && ($bodystructure->type eq 'multipart'));
ok_if(54, defined($bodystructure) && ($bodystructure->subtype eq 'mixed'));

my $parts = $bodystructure->parts if defined($bodystructure);
ok_if(55, scalar(@{$parts}) == 3);
$parms = $bodystructure->parameters if defined($bodystructure);
ok_if(56, ref($parms) eq 'HASH');
my $list = $bodystructure->language if defined($bodystructure);
ok_if(57, (scalar(@{$list}) == 1) && ($list->[0] eq 'en'));

$envelope = $parts->[1]->envelope if defined($parts);
$to = $envelope->to if defined($envelope);
$addr = $to->[0] if defined($to);
ok_if(58, defined($envelope));
ok_if(59, defined($to));
ok_if(60, defined($addr) && $addr->isa('Net::IMAP::Addr'));

my $parts2 = $parts->[2]->parts;
ok_if(61, defined($parts2) && (scalar(@{$parts2}) == 2));

#------------------------------------------------------------------------------
# test crlf<->lf mapping
$imap->{Options}{EOL} = 'crlf';
$response = $imap->fetch(1, qw(body.peek[]));
ok_if(62, $response->status eq 'ok');
$body = $fetch_resp->item('body[]');
ok_if(63, $body ne $testmsg);
$body =~ s/\r$//mg if defined($body);
ok_if(64, $body eq $testmsg);
#------------------------------------------------------------------------------
my $list_has_inbox = 0;
$response = $imap->list('', 'inbox');
ok_if(65, $list_has_inbox);
#------------------------------------------------------------------------------
$response = $imap->expunge;
ok_if(66, $response->status eq 'ok');
ok_if(67, $imap->qty_messages == 1);
#------------------------------------------------------------------------------
$response = $imap->close;
ok_if(68, $response->status eq 'ok');

$response = $imap->status($testfolder, 'messages');
ok_if(69, $response->status eq 'ok');
ok_if(70, defined($status));

ok_if(71, (defined($status->item('messages'))
	   && ($status->item('messages') == 1)));

$response = $imap->delete($testfolder);
ok_if(72, $response->status eq 'ok');

$response = $imap->logout;
ok_if(73, defined($response));
###############################################################################
sub do_fetch {
  my $self = shift;
  my $resp = shift;

  $fetch_resp = $resp;		# make it available to the test
}

sub do_status {
  my $self = shift;
  my $resp = shift;

  $status = $resp if ($resp->mailbox eq $testfolder);
}

sub do_search {
  my $self = shift;
  my $resp = shift;

  @search_items = $resp->msgnums;
}

sub do_list {
  my $self = shift;
  my $resp = shift;

  $list_has_inbox++ if (lc($resp->mailbox) eq 'inbox');
}
#------------------------------------------------------------------------------
sub ok_if {
  print "not " unless $_[1];
  print "ok $_[0]\n";
}
###############################################################################
