
use strict;
use Net::ESMTP qw(:all smtp_errno smtp_strerror smtp_version);
use Getopt::Long;

our $i = 0;

my $session = new Net::ESMTP::Session ();
my $message = $session->add_message();

#
## Getopt
#

my $host = "localhost:25";
my $from;
my $subj;
my $nocrlf;
my $use_auth = 0;

my %h = ('host' => \$host, 'from' => \$from, 'subjéct' => \$subj,
         'crlf' => \$nocrlf, 'auth' => \$use_auth);
GetOptions (\%h,
            'help|?','version|v','host|h=s','monitor|m',
    	    'crlf|c','notify|n=s','mdn|d','subject|s=s',
    	    'reverse-path|f=s','tls|t','require-tls|T','auth|a');

my $notify = Notify_NOTSET;
if (exists $h{'notify'}) {
	if ($h{'notify'} eq 'success') {
		$notify |= Notify_SUCCESS;
	} elsif ($h{'notify'} eq 'failure') {
		$notify |= Notify_FAILURE;
	} elsif ($h{'notify'} eq 'delay') {
		$notify |= Notify_DELAY;
	} elsif ($h{'notify'} eq 'never') {
		$notify |= Notify_NEVER;
	}
}

$session->set_monitorcb (\&monitorcb, 0, 1)
	if exists $h{'monitor'};
$message->set_header ("Disposition-Notification-To", undef, undef)
	if exists $h{'mdn'};
$session->starttls_enable (Starttls_ENABLED)
	if exists $h{'tls'};
$session->starttls_enable (Starttls_REQUIRED)
	if exists $h{'require-tls'};
do {
	print "Net::ESMTP version " . $Net::ESMTP::VERSION . "\n";
	print "based on libESMTP version " . smtp_version() . "\n";
	exit 0;
} if exists $h{'version'};

#
## At least 2 more arguments are needed
#
if (@ARGV < 2) {
	&usage ();
	exit 2;
}

$session->set_server ($host);

#
## auth
#
my $auth = new Net::ESMTP::Auth();
$auth->set_mechanism_flags(AUTH_PLUGIN_PLAIN, 0);
$auth->set_interact_cb(\&authinteract, undef);

# harmless if TLS is not is use
Net::ESMTP::starttls_set_password_cb (\&tlsinteract);
# ESMTP can now use the SMTP AUTH extension.
if ($use_auth) {
  $session->auth_set_context ($auth);
}

#
# message
#
# Set the reverse path for the mail envelope. (undef is ok)
$message->set_reverse_path ($from);
# add To header optionally
$message->set_header ("To", undef, undef);

# set subject is specified
if (defined $subj) {
	$message->set_header ("Subject", $subj);
	$message->set_header_option ("Subject", Hdr_OVERRIDE, 1);
}

# open a message file
my $file = shift(@ARGV);
if (!-f $file) {
  die "File $file is not a plain file";
}

open FH, "<$file" || die "Can not open $file: $!";

if ($nocrlf) {
	$message->set_messagecb (\&readlinefp, \*FH);
} else {
	$message->set_message_fp (\*FH);
}

# add remaining arguments as recipients
for (@ARGV) {
  my $recipient = $message->add_recipient ($_);
  $recipient->dsn_set_notify ($notify);
}

#
# send message
#
if (!$session->start_session ()) {
    warn "SMTP server problem: " .
	smtp_strerror (smtp_errno ()) . "\n";
} else {
    my $status = $message->message_transfer_status();
    print $status->{'code'} . ' ' . $status->{'text'};
    $message->enumerate_recipients (\&rcpt_status, 'RCPT: ');
}

#
# cleanup
#

undef $session; # done automatically at program end, but it is for completeness.
undef $auth; # the same as above

close (FH) || die "Close $file: $!";

#
## END
#

sub rcpt_status {
  my ($rcpt, $mailbox, $user_data) = @_;
  my $status = $rcpt->recipient_status ();
  print $user_data . $mailbox . ': ' . $status->{'code'} . ' ' . $status->{'text'};
}

sub monitorcb {
  my ($line, $writing, $user_data) = @_;
  if ($writing == 2) {
    print 'H: ';
  } else {
    print (($writing == 1) ? 'C: ' : 'S: ');
  }
  print $line;
}

sub authinteract {
    my @ret;
    #use Data::VarPrint;
    #VarPrint(@_);
    
    my ($requests, $data) = @_;
    my $fields = scalar @{$requests};
    for (my $i=0; $i<$fields; ++$i) {
	my $req = $requests->[$i];
	next if ref $req ne 'HASH';
	my $prompt = $req->{'prompt'} .
	   (($req->{'flags'} & AUTH_CLEARTEXT) ? " (not encrypted)" : "");
	my $resp = &getpass ($prompt);
	push (@ret, $resp);
    }
    return @ret;
}

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

sub tlsinteract {
    return &getpass("certificate password");
}

sub getpass {
    my $pw;
    my $prompt = shift(@_);
    local $| = 1;
    print $prompt . ": ";
    chomp($pw = <STDIN>);
    $pw =~ s/^\s+//;
    return $pw;
}

sub usage {
print <<'END';
This perl version is rewritten by Piotr Klaban <post@man.torun.pl>

Original mail-file.c is copyrighted by:

Copyright (C) 2001  Brian Stafford <brian@stafford.uklinux.net>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
by the Free Software Foundation; either version 2 of the License,
or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

usage: mail-file [options] file mailbox [mailbox ...]
	-h,--host=hostname[:service] -- set SMTP host and service (port)
	-f,--reverse-path=mailbox -- set reverse path
	-s,--subject=text -- set subject of the message
	-n,--notify=success|failure|delay|never -- request DSN
	-d,--mdn -- request MDN
	-m,--monitor -- watch the protocol session with the server
	-c,--crlf -- translate line endings from \n to CR-LF
	-t,--tls -- use STARTTLS extension if possible
	-T,--require-tls -- require use of STARTTLS extension
	-a,--auth -- use SMTP AUTH
	--version -- show version info and exit
	--help -- this message

Specify the file argument as "-" to read standard input.
The input must be in RFC 2822 format, that is, it must consist
of a sequence of message headers terminated by a blank line and
followed by the message body.  Lines must be terminated with the
canonic CR-LF sequence unless the --crlf flag is specified.
Total line length must not exceed 1000 characters.
END
}

