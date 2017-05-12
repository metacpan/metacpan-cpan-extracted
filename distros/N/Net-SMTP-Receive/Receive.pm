
#
# BUGS:
#	cannot handle address with spaces in them
#

package Net::SMTP::Receive;

use vars qw($VERSION);
$VERSION = 0.301;

use strict;
use Socket;
use IO::Socket;
require Sys::Hostname;
use File::Slurp;
use File::Flock;
use Sys::Syslog;
use Time::CTime;
use Net::Ident 'ident_lookup';
use Storable;
require POSIX;
use POSIX qw(O_CREAT O_RDWR);
require File::Sync;

my $server;


#	#	#	#	#	#	#	#	#
#	#	#	#	#	#	#	#	#
#
# 	The following MUST be replaced in the subclass.		#
#
#	#	#	#	#	#	#	#	#
#	#	#	#	#	#	#	#	#


sub deliver { my($message) = @_; die "deferred"; }

sub is_delivered { my($message) = @_; die "deferred"; }

#	#	#	#	#	#	#	#	#
#	#	#	#	#	#	#	#	#
#
# 	The following functions are expected to be replaced 	#
#	in the subclass						#
#
#	#	#	#	#	#	#	#	#
#	#	#	#	#	#	#	#	#

# error codes:
#
#	4?? - temporary problems - should try again
#	451 - local error
#	452 - insufficient storage
#	421 - shutdown, closing channel
#	5?? - permanent problems - do not try again
#	500 - line too long (??)
#	501 - path too long (??)
#	552 - too many recipients (??)
#	552 - too much mail data (??)
#	554 - transmission/transaction failed
#

sub predeliver { my($server,$client,$msgref) = @_; }

sub prestart { } 

sub do_syslog { 1; } 

sub checkaccess { } 

sub check_mailfrom { 0; }

sub queue_directory { '/var/spool/pmqueue'; }

sub process_only_one_message { 0; }

#
# error codes:
#
#	550 relaying denied.
#	550 user unknown
#

sub check_rcptto { 0; }

#	#	#	#	#	#	#	#	#
#	#	#	#	#	#	#	#	#
#
# 	It is less likely you'll want to replace these		#
#
#	#	#	#	#	#	#	#	#
#	#	#	#	#	#	#	#	#

sub port { 'smtp(25)'; }

sub ipaddr { undef; } # INADDR_ANY

sub max_datalength { 20_000_000; }

sub max_recipients { 10_000; }

sub logcode { 'info'; }

sub logfacility { 'mail'; }

sub add_envelope { 0; }

sub do_ident { 1; }

sub progname
{
	$0 =~ /(\S+)/;
	return $0;
}

sub address_check
{
	my ($server, $addr) = @_;

	return "501parameter unrecognized" unless 
		$addr =~ /^(?:[^"'\s]+|"[^"]*"|'[^']*')+$/;
	return "Domain name rquired" unless $addr =~ /\S\@\S/;
	return "Could not parse" unless $addr =~ /^<\S+\@\S+\S>$/
		|| $addr =~ /[^<]\S*\@\S*[^>]/;
	return '';
}

my $hostname;
sub hostname
{
	return $hostname if $hostname;
	$hostname = Sys::Hostname::hostname();
}

sub handleDie
{
	return if $;
	my ($server, $msg) = @_;
	print STDERR "DIE: $msg\n";
	$server->log("%s", "died: $msg");
	exit(1);
}

sub handleWarn
{
	return if $;
	my ($server, $msg) = @_;
	print STDERR "WARN: $msg\n";
	$server->log("%s", "warning: $msg");
}

sub default_delivery_error { 554; }

sub help
{
	return <<END;
214-This is the perl module Net::STMP::Receive version $VERSION
214-
214-It supports the following normal SMTP commands:
214-    HELO   MAIL   RCPT   DATA
214-    EHLO   QUIT
214-For more information, see the module documenation at
214-http://www.cpan.org
214 End of HELP info
END
}


my $logopen;
sub log
{
	my ($server, $text, @args) = @_;

	if ($server->do_syslog || ! $logopen) {
		Sys::Syslog::openlog($server->progname, "pid", 
				$server->logfacility);
	}
	$logopen = 1;
	syslog($server->logcode, $text, @args)
		if $server->do_syslog;
	printf STDERR "*** $text\n", @args;
}

sub qf_cookie { 'pMR1:'; }


#	#	#	#	#	#	#	#	#
#	#	#	#	#	#	#	#	#
#
# It is unlikly you'll want to replace any of the following
#
#	#	#	#	#	#	#	#	#
#	#	#	#	#	#	#	#	#

sub server
{
	my ($pkg, %config) = @_;

	$server = { %config };
	bless ($server, $pkg);

	$server->prestart(%config);

	my $port = $config{'Port'} || $server->port();
	my $ip = $config{'IpAddr'};
	$ip = $server->ipaddr() unless defined $ip;

	my $listen = new IO::Socket::INET (
			'LocalAddr' => $ip,
			'LocalPort' => $port,
			'Proto' => 'tcp',
			'Reuse' => 1,
			'Listen' => 20,
		);

	unless ($listen) {
		$server->log("Could not bind to port %s:%s: %s", $ip, $port, $!);
		return 0;
	}

	$server->log("Now listening at %s:%s", $ip, $port);

	$SIG{'__DIE__'} = \&handleDieSig;
	$SIG{'__WARN__'} = \&handleWarnSig;

	$server->mainloop($listen);
}

sub mainloop
{
	my ($server, $listen) = @_;
	for(;;) {
		my $client = $listen->accept;

		if ($server->process_only_one_message()) {
			close($listen);
			$server->talk($client);

			again();
			return;
		}

		my $pid;
		for (;;) {
			$pid = fork();
			if (! defined($pid)) {
				warn("fork: $!");
				sleep 1;
				redo;
			}
			if ($pid == 0) {
				my $pid2;
				for (;;) {
					$pid2 = fork();
					if (! defined($pid2)) {
						warn("fork: $!");
						sleep 1;
						redo;
					}
					last;
				}
				if ($pid2 == 0) {
					$listen->close;
					exit($server->talk($client));
				}
				exit(0);
			}
			last;
		}
		close($client);

		rand(1);
		rand(1);
		rand(1);

		waitpid($pid,0);
	}
}

sub talk
{
	my ($server, $client) = @_;

	$server->log("Accepted connection from %s", $client->peerhost());

	$client->sockopt(SO_KEEPALIVE, 1);

	$server->{'PEERADDR'} = $client->peerhost();
	$server->{'PEERHOST'} = gethostbyaddr($client->peeraddr(), AF_INET);

	if ($server->do_ident) {
		my ($username, $opsys, $error) = ident_lookup($client, 30);
		if (! defined $username) {
			$server->log("Ident lookup failed %s: %s", $client->peerhost(), $error);
		} else {
			$server->log("Ident lookup %s: %s", $client->peerhost(), $username);
			$server->{'IDENT'} = $username;
		}
	}
	$server->checkaccess($client, $server->{'IDENT'});

	my $hostname = $server->hostname();
	my $date = strftime("%c GMT", gmtime(time));
	print $client "220 $hostname ESMTP Net::SMTP::Receive $VERSION; $date\r\n";

	$server->reset();

	while(<$client>) {
		s/\r?\n$//;
		if (/^help\b/i) {
			print $client $server->help();
		} elsif (/^quit/i) {
			print $client "221 $hostname closing connection\r\n";
			$server->log("Closing connection to %s", $client->peerhost());
			last;
		} elsif (s/^helo\b//i) {
			s/^\s*//;
			s/\s*\r?\n$//;
			$server->{'HELO'} = $_;
			print $client "220 hello $_!\r\n";
		} elsif (/^mail\b/i) {
			$server->mail($client,$_);
		} elsif (/^rcpt\b/i) {
			$server->rcpt($client,$_);
		} elsif (/^data\b/i) {
			$server->data($client,$_);
		} elsif (/^(noop|vrfy|expn|verb|etrn|dsn)\b/i) {
			print $client "501 Command not implemented\r\n";
		} elsif (/^(send|soml|saml|turn)\b/i) {
			print $client "501 Command unusual\r\n";
		} elsif (/^rset\b/i) {
			$server->reset();
			print $client "250 Reset state\r\n";
		} elsif (/^ehlo\b/i) {
			s/^\s*//;
			s/\s*\r?\n$//;
			$server->{'HELO'} = $_;
			my $h = $server->hostname;
			print $client "220-$h says hi, we support:\r\n";
			print $client "220 8BITMIME\r\n";
		} else {
			m/^(\.+?)\b/;
			print $client qq'500 Command unrecognized: "$1"\r\n';
		}
	}
	$server->log("Lost idle connection to %s", $client->peerhost())
		unless $_ && /^quit/i;
	eval {$client->close;};
	return 0;
}

sub stageok
{
	my ($server, $client, $func, $func2) = @_;
	return 1 if $func eq $server->{'STATE'};
	return 1 if $func2 eq $server->{'STATE'};
	print $client "503 Need $server->{STATE} command\r\n";
	return 0;
}

sub mail
{
	my ($server, $client, $command) = @_;

	return unless $server->stageok($client, 'MAIL');

	unless ($command =~ s/^mail\s+//i) {
		print $client "500 mail command unrecognized\r\n";
		return;
	}
	$command =~ s/\s+$//;
	unless ($command =~ s/^from://i) {
		print $client "501 syntax error at \"$command\"\r\n";
		return;
	}
	$command =~ s/^\s+//;
	if ($command =~ s/\s+body=(\S+)\s*$//i) {
		my $mt = $1;
		if ("\U$mt" eq '8BITMIME' || "\U$mt" eq '7BIT') {
			$server->{'MIMETYPE'} = $mt;
		} else {
			print $client "502-Body type $mt not implemented\r\n";
		}
	}
	my $addr = $command;
	my $aer = $addr eq '<>' 
		? ''
		: $server->address_check($addr);
	if ($aer) {
		$aer =~ s/^(\d\d\d)//;
		my $ec = $1 || '553';
		print $client "$ec $addr... $aer\r\n";
		$server->log("mail from error: %s... %s %s", $addr, $ec, $aer);
		return;
	}
	my $er = $server->check_mailfrom($addr);
	if ($er) {
		$er =~ s/^(\d\d\d)//;
		my $ec = $1 || '553';
		print $client "$ec $addr... $er\r\n";
		$server->log("mail from error: %s... %s %s", $addr, $ec, $er);
		return;
	}
	$server->{'FROM'} = $addr;
	$server->{'STATE'} = 'RCPT';
	print $client "250 $addr... Sender OK\r\n";
}

sub rcpt
{
	my ($server, $client, $command) = @_;

	return unless $server->stageok($client, 'DATA', 'RCPT');

	unless ($command =~ s/^rcpt\s+//i) {
		print $client "500 rcpt command unrecognized\r\n";
		return;
	}
	$command =~ s/\s+$//;
	unless ($command =~ s/^to://i) {
		print $client "501 syntax error at \"$command\"\r\n";
		return;
	}
	$command =~ s/^\s+//;
	my $addr = $command;
	my $aer = $server->address_check($addr);
	if ($aer) {
		$aer =~ s/^(\d\d\d)//;
		my $ec = $1 || '553';
		print $client "$ec $addr... $aer\r\n";
		$server->log("rcpt to error: %s... %s %s", $addr, $ec, $aer);
		return;
	}
	my ($er, @newaddr) = $server->check_rcptto($addr);
	if ($er) {
		$er =~ s/^(\d\d\d)//;
		my $ec = $1 || '553';
		print $client "$ec $addr... $er\r\n";
		$server->log("rcpt to error: %s... %s %s", $addr, $ec, $er);
		return;
	}
	if ($#{$server->{'TO'}} > $server->max_recipients) {
		$server->log("Too many recipients: %s", $client->peerhost());
		print $client "552 Too many recipients\r\n";
		$server->reset();
		return;
	}
	push(@{$server->{'TO'}}, (@newaddr ? @newaddr : $addr));
	$server->{'STATE'} = 'DATA';
	print $client "250 $addr... Recipient OK\r\n";
}

sub data
{
	my ($server, $client) = @_;
	return unless $server->stageok($client,'DATA');

	print $client $server->{'MIMETYPE'}
		? "354 Send $server->{MIMETYPE} message, ending in CLRF.CLRF\r\n"
		: qq'354 Enter mail, end with "." on a line by itself\r\n';

	my $eight = $server->{MIMETYPE} && "\U$server->{MIMETYPE}" eq '8BITMIME';
	my $p = 0;
	my $len;
	my @msg;

	my $date = strftime("%c GMT", gmtime(time));
	my $h3 = $server->hostname();
	my $from = $server->{FROM};
	$from =~ s/^<(.*)>$/$1/;
	$from = "mailer-daemon\@$h3" if $from eq '';

	push (@msg,"From $from $date\n");
	if ($server->add_envelope) {
		for my $t (@{$server->{'TO'}}) {
			push (@msg, "X-Envelope-To: $t\n");
		}
	}

	my $h0 = $server->{'PEERHOST'};
	my $h1 = $server->{'PEERADDR'} || $h0;
	my $h2 = $server->{'HELO'} || $h1;

	push(@msg, "Received: from $h2 ($h1 [$h0]) by $h3 ($VERSION); $date\n");
	while(<$client>) {
		if ($eight ? ($p && $_ eq ".\r\n") : /^\.[\r\n]*$/) {
			if ($len >= $server->max_datalength) {
				$server->log("Message via %s rejected: too long", $client->peerhost());
				print $client "552 Max data length exceeded\r\n";
				return;
			}
			my $id;
			undef $@;
			eval { $id = $server->enqueue($client, \@msg); };
			if ($@) {
				my $x = $@;
				$x =~ s/[\r\n]/... /g;
				$x =~ s/^(\d\d\d)//;
				my $er = $1 || $server->default_delivery_error;
				print $client "$er Message rejected: $x\r\n";
				$server->log("Message via %s rejected: %s", $client->peerhost(), "$er $x");
				$server->reset();
				return;
			}
			$server->log("Message %s via %s accepted: %s", $id, $client->peerhost(), $id);
			print $client "250 $id Message accepted for delivery\r\n";
			$server->reset();

			$server->runqueue($id);

			again() if $server->process_only_one_message();

			return;
		}
		$p = s/\r\n$/\n/;
		$len += length($_) if defined $_;
		if ($len < $server->max_datalength) {
			push(@msg, $_);
		}
	}
	$server->log("Lost connection to %s", $client->peerhost());
	$server->reset();
	return;
}

sub enqueue
{
	my ($server, $client, $msgref) = @_;

	$server->predeliver($client, $msgref);

	my $qd = $server->queue_directory();
	my $id = int(rand(100_000_000));
	for (;;) {
		$id-- while -e "$qd/$id.pqf";
		lock "$qd/$id.pqf", undef, 'nonblocking'
			or next;
		last if ! -s "$qd/$id.pqf";
		unlock "$qd/$id.pqf";
		$id--;
	}

	$server->{'TIME'} = time;
	$server->{'ID'} = $id;
	$server->{'TEXTFILE'} = "$qd/$id.txt";
	$server->syncwrite($server->{'TEXTFILE'}, join('',@$msgref));

	my $newfrozen = Storable::nfreeze($server);
	$server->syncwrite("$qd/$id.pqf.new", $server->qf_cookie, $newfrozen);

	rename("$qd/$id.pqf.new", "$qd/$id.pqf")
		or die "rename $qd/$id.pqf.new -> $qd/$id.pqf: $!";

	unlock "$qd/$id.pqf";

	$server->log("messaged assigned id %s and queued", $id);
	return $id;
}

sub showqueue
{
	my ($ref, @id) = @_;

	my $lead = "\t\tMail Queue\n-id-\t\t-size-\-status-\n";
	my $pkg = ref $ref || $ref;
	my $qd = ${pkg}->queue_directory;
	unless (@id) {
		for my $f (read_dir($qd)) {
			next unless $f =~ /^(\d+)\.pqf$/;
			push(@id, $1);
		}
	}
	for my $id (@id) {
		my $file = "$qd/$id.pqf";
		lock $file;
		if (! -s $file) {
			unlock $file;
			unlink $file;
			next;
		}
		my $size = -s "$qd/$id.txt";
		$lead .= "$id  \t$size\t";
		my $frozen = read_file($file);
		my $cookie = ${pkg}->qf_cookie;
		unless ($frozen =~ /^\Q$cookie\E(.*)$/s) {
			unlock $file;
			print "$lead\tCorrupt queue file\n";
			next;
		}
		my $message = Storable::thaw $1;
		print "${lead}From $message->{'FROM'}: $message->{'ERROR'}\n";

		for my $to (@{$message->{'TO'}}) {
			die "TO is a reference in $id" if ref $to;
			my $status = $message->is_delivered($to);
			print "\t\t$to: $status\n";
		}
		unlock $file;
	} continue {
		$lead = '';
	}
	print "Mail Queue is empty\n" if $lead;
}

sub runqueue
{
	my ($ref, @id) = @_;

	my $pkg = ref $ref || $ref;
	my $qd = ${pkg}->queue_directory;
	unless (@id) {
		for my $f (read_dir($qd)) {
			next unless $f =~ /^(\d+)\.pqf$/;
			push(@id, $1);
		}
	}
	my $file;
	for my $id (@id) {
		$file = "$qd/$id.pqf";
		lock $file;
		if (! -s $file) {
			unlock $file;
			unlink $file;
			next;
		}
		${pkg}->log("Processing mailq queue file %s", $file);
		my $frozen = read_file($file);
		my $cookie = ${pkg}->qf_cookie;
		unless ($frozen =~ /^\Q$cookie\E(.*)$/s) {
			unlock $file;
			${pkg}->log("Corrupt mail queue file: %s", $file);
			next;
		}
		my $message = Storable::thaw $1;
		if ($message->is_delivered) {
			${pkg}->log("Message %s is delivered", $id);
			unlink "$qd/$id.txt";
			unlink $file;
#$message->resave;
			next;
		}
		${pkg}->log("Attempting delivery of %s", $id);
		eval { $message->deliver(); };
		$message->{'ERROR'} = $@;
		$message->{'LASTQRUN'} = time;
		if ($message->is_delivered) {
			${pkg}->log("Message %s is delivered", $id);
			unlink "$qd/$id.txt";
			unlink $file;
#$message->resave;
			next;
		} else {
			${pkg}->log("Delivery error: %s", $message->{'ERROR'})
				if $message->{'ERROR'};
			${pkg}->log("Message %s is still pending", $id);
			$message->resave;
		}
	} continue {
		unlock $file;
	}
}

sub resave
{
	my ($message) = @_;
	my $newfrozen = Storable::nfreeze($message);
	my $qd = $message->queue_directory;
	my $id = $message->{'ID'};
	$message->syncwrite("$qd/$id.pqf.new", $message->qf_cookie, $newfrozen);
	lock "$qd/$id.pqf.new";
	rename("$qd/$id.pqf.new", "$qd/$id.pqf")
		or die "rename $qd/$id.pqf.new -> $qd/$id.pqf: $!";
	unlock "$qd/$id.pqf";
	File::Flock::lock_rename ("$qd/$id.pqf.new", "$qd/$id.pqf");
}

sub textfile
{
	my ($message) = @_;
	$message->{'TEXTFILE'};
}

sub handleDieSig
{
	$server->handleDie(@_);
}


sub handleWarnSig
{
	$server->handleWarn(@_);
}

sub syncwrite
{
	my ($server, $f, @data) = @_;
	no strict;

	local(*F,*O);
	open(F, ">$f") || die "open >$f: $!";
	$O = select(F);
	$| = 1;
	select($O);
	(print F @data) || die "write $f: $!";
	File::Sync::fsync_fd(fileno(F)) || die "fsync $f: $!";
	close(F) || die "close $f: $!";
	return 1;
}

sub reset
{
	$server->{'STATE'} = 'MAIL';
	undef $server->{'FROM'};
	$server->{'TO'} = [];
	$server->{'MIMETYPE'} = '';
	undef $server->{'HELO'};
	undef $server->{'TIME'};
	undef $server->{'ID'};
	undef $server->{'TEXTFILE'};
}

sub again
{
	print STDERR "\n\nHIT RETURN TO PROCESS ANOTHER\n\n";
	my $x = <STDIN>;
}

1;
