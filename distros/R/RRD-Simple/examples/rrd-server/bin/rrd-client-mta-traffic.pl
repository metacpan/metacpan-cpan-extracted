#!/usr/bin/perl -w
############################################################
#
#   $Id$
#   rrd-client-mta.pl - MTA data gathering script for rrd-server.pl
#
#   Copyright 2007, 2008 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################
# vim:ts=4:sw=4:tw=78

use constant MAIL_LOG       => '/var/log/maillog';
use constant RRD_SERVER_URL => 'http://rrd.me.uk/cgi-bin/rrd-server.cgi';
use constant DEBUG          => $ENV{DEBUG} ? 1 : 0;
use constant RRD_STEPPING   => 60; # seconds

############################################################
#
#    NO USER SERVICABLE PARTS BEYOND THIS POINT
#
############################################################


use 5.6.1;
use strict;
use warnings;

use Parse::Syslog qw();
use File::Tail qw();
use Getopt::Std qw();
use LWP::UserAgent qw();
use HTTP::Request::Common qw();
use Proc::DaemonLite qw();

our $VERSION = sprintf('%d.%02d', q$Revision: 1.1 $ =~ /(\d+)/g);

my $this_minute;
my %opt = ('ignore-localhost' => 1);
my %sum = map { $_ => 0 } qw(sent received bounced rejected spam virus);

#my $tail = File::Tail->new(name => MAIL_LOG, tail => -1);
my $tail = File::Tail->new(name => MAIL_LOG, tail => 0);

my $parser = new Parse::Syslog($tail,
		year     => (localtime(time))[5]+1900,
		arrayref => 1,
		type     => 'syslog'
	);

my $pid = Proc::DaemonLite::init_server();

while (my $sl = $parser->next) {
	process_line($sl);
}

exit;


sub process_line {
	my $sl   = shift;
	my $time = $sl->[0];
	my $prog = $sl->[2];
	my $text = $sl->[4];

	if($prog eq 'exim') {
		if($text =~ /^[0-9a-zA-Z]{6}-[0-9a-zA-Z]{6}-[0-9a-zA-Z]{2} <= \S+/) {
			event($time, 'received');
		}
		elsif($text =~ /^[0-9a-zA-Z]{6}-[0-9a-zA-Z]{6}-[0-9a-zA-Z]{2} => \S+/) {
			event($time, 'sent');
		}
# rejected after DATA: Your message scored 10.4 SpamAssassin point. Report follows:
		elsif($text =~ / rejected because \S+ is in a black list at \S+/) {
			if($opt{'rbl-is-spam'}) {
				event($time, 'spam');
			} else {
				event($time, 'rejected');
			}
		}
		elsif($text =~ / rejected RCPT \S+: (Sender verify failed|Unknown user)/) {
			event($time, 'rejected');
		}
	}
	elsif($prog =~ /^postfix\/(.*)/) {
		my $prog = $1;
		if($prog eq 'smtp') {
			if($text =~ /\bstatus=sent\b/) {
				return if $opt{'ignore-localhost'} and
					$text =~ /\brelay=[^\s\[]*\[127\.0\.0\.1\]/;
				return if $opt{'ignore-host'} and
					$text =~ /\brelay=[^\s,]*$opt{'ignore-host'}/oi;
				event($time, 'sent');
			}
			elsif($text =~ /\bstatus=bounced\b/) {
				event($time, 'bounced');
			}
		}
		elsif($prog eq 'local') {
			if($text =~ /\bstatus=bounced\b/) {
				event($time, 'bounced');
			}
		}
		elsif($prog eq 'smtpd') {
			if($text =~ /^[0-9A-Z]+: client=(\S+)/) {
				my $client = $1;
				return if $opt{'ignore-localhost'} and
					$client =~ /\[127\.0\.0\.1\]$/;
				return if $opt{'ignore-host'} and
					$client =~ /$opt{'ignore-host'}/oi;
				event($time, 'received');
			}
			elsif($opt{'virbl-is-virus'} and $text =~ /^(?:[0-9A-Z]+: |NOQUEUE: )?reject: .*: 554.* blocked using virbl.dnsbl.bit.nl/) {
				event($time, 'virus');
			}
			elsif($opt{'rbl-is-spam'} and $text    =~ /^(?:[0-9A-Z]+: |NOQUEUE: )?reject: .*: 554.* blocked using/) {
				event($time, 'spam');
			}
			elsif($text =~ /^(?:[0-9A-Z]+: |NOQUEUE: )?reject: /) {
				event($time, 'rejected');
			}
		}
		elsif($prog eq 'error') {
			if($text =~ /\bstatus=bounced\b/) {
				event($time, 'bounced');
			}
		}
		elsif($prog eq 'cleanup') {
			if($text =~ /^[0-9A-Z]+: (?:reject|discard): /) {
				event($time, 'rejected');
			}
		}
	}
	elsif($prog eq 'sendmail' or $prog eq 'sm-mta') {
		if($text =~ /\bmailer=local\b/ ) {
			event($time, 'received');
		}
                elsif($text =~ /\bmailer=relay\b/) {
                        event($time, 'received');
                }
		elsif($text =~ /\bstat=Sent\b/ ) {
			event($time, 'sent');
		}
                elsif($text =~ /\bmailer=esmtp\b/ ) {
                        event($time, 'sent');
                }
		elsif($text =~ /\bruleset=check_XS4ALL\b/ ) {
			event($time, 'rejected');
		}
		elsif($text =~ /\blost input channel\b/ ) {
			event($time, 'rejected');
		}
		elsif($text =~ /\bruleset=check_rcpt\b/ ) {
			event($time, 'rejected');
		}
                elsif($text =~ /\bstat=virus\b/ ) {
                        event($time, 'virus');
                }
		elsif($text =~ /\bruleset=check_relay\b/ ) {
			if (($opt{'virbl-is-virus'}) and ($text =~ /\bivirbl\b/ )) {
				event($time, 'virus');
			} elsif ($opt{'rbl-is-spam'}) {
				event($time, 'spam');
			} else {
				event($time, 'rejected');
			}
		}
		elsif($text =~ /\bsender blocked\b/ ) {
			event($time, 'rejected');
		}
		elsif($text =~ /\bsender denied\b/ ) {
			event($time, 'rejected');
		}
		elsif($text =~ /\brecipient denied\b/ ) {
			event($time, 'rejected');
		}
		elsif($text =~ /\brecipient unknown\b/ ) {
			event($time, 'rejected');
		}
		elsif($text =~ /\bUser unknown$/i ) {
			event($time, 'bounced');
		}
		elsif($text =~ /\bMilter:.*\breject=55/ ) {
			event($time, 'rejected');
		}
	}
	elsif($prog eq 'amavis' || $prog eq 'amavisd') {
		if(   $text =~ /^\([0-9-]+\) (Passed|Blocked) SPAM(?:MY)?\b/) {
			event($time, 'spam'); # since amavisd-new-2004xxxx
		}
		elsif($text =~ /^\([0-9-]+\) (Passed|Not-Delivered)\b.*\bquarantine spam/) {
			event($time, 'spam'); # amavisd-new-20030616 and earlier
		}
		### UNCOMMENT IF YOU USE AMAVISD-NEW <= 20030616 WITHOUT QUARANTINE: 
		#elsif($text =~ /^\([0-9-]+\) Passed, .*, Hits: (\d*\.\d*)/) {
		#	if ($1 >= 5.0) {      # amavisd-new-20030616 without quarantine
		#		event($time, 'spam');
		#	}
		#}
		elsif($text =~ /^\([0-9-]+\) (Passed |Blocked )?INFECTED\b/) {
			if($text !~ /\btag2=/) { # ignore new per-recipient log entry (2.2.0)
				event($time, 'virus');# Passed|Blocked inserted since 2004xxxx
			}
		}
		elsif($text =~ /^\([0-9-]+\) (Passed |Blocked )?BANNED\b/) {
			if($text !~ /\btag2=/) {
			       event($time, 'virus');
			}
		}
#		elsif($text =~ /^\([0-9-]+\) Passed|Blocked BAD-HEADER\b/) {
#		       event($time, 'badh');
#		}
		elsif($text =~ /^Virus found\b/) {
			event($time, 'virus');# AMaViS 0.3.12 and amavisd-0.1
		}
	}
	elsif($prog eq 'vagatefwd') {
		# Vexira antivirus (old)
		if($text =~ /^VIRUS/) {
			event($time, 'virus');
		}
	}
	elsif($prog eq 'hook') {
		# Vexira antivirus
		if($text =~ /^\*+ Virus\b/) {
			event($time, 'virus');
		}
		# Vexira antispam
		elsif($text =~ /\bcontains spam\b/) {
			event($time, 'spam');
		}
	}
	elsif($prog eq 'avgatefwd' or $prog eq 'avmailgate.bin') {
		# AntiVir MailGate
		if($text =~ /^Alert!/) {
			event($time, 'virus');
		}
		elsif($text =~ /blocked\.$/) {
			event($time, 'virus');
		}
	}
	elsif($prog eq 'avcheck') {
		# avcheck
		if($text =~ /^infected/) {
			event($time, 'virus');
		}
	}
	elsif($prog eq 'spamd') {
		if($text =~ /^(?:spamd: )?identified spam/) {
			event($time, 'spam');
		}
		# ClamAV SpamAssassin-plugin
		elsif($text =~ /(?:result: )?CLAMAV/) {
			event($time, 'virus');
		}
	}
	elsif($prog eq 'dspam') {
		if($text =~ /spam detected from/) {
			event($time, 'spam');
		}
	}
	elsif($prog eq 'spamproxyd') {
		if($text =~ /^\s*SPAM/ or $text =~ /^identified spam/) {
			event($time, 'spam');
		}
	}
	elsif($prog eq 'drweb-postfix') {
		# DrWeb
		if($text =~ /infected/) {
			event($time, 'virus');
		}
	}
	elsif($prog eq 'BlackHole') {
		if($text =~ /Virus/) {
			event($time, 'virus');
		}
		if($text =~ /(?:RBL|Razor|Spam)/) {
			event($time, 'spam');
		}
	}
	elsif($prog eq 'MailScanner') {
		if($text =~ /(Virus Scanning: Found)/ ) {
			event($time, 'virus');
		}
		elsif($text =~ /Bounce to/ ) {
			event($time, 'bounced');
		}
		elsif($text =~ /^Spam Checks: Found ([0-9]+) spam messages/) {
			my $cnt = $1;
			for (my $i=0; $i<$cnt; $i++) {
				event($time, 'spam');
			}
		}
	}
	elsif($prog eq 'clamsmtpd') {
		if($text =~ /status=VIRUS/) {
			event($time, 'virus');
		}
	}
	elsif($prog eq 'clamav-milter') {
		if($text =~ /Intercepted/) {
			event($time, 'virus');
		}
	}
	# uncommment for clamassassin:
	#elsif($prog eq 'clamd') {
	#	if($text =~ /^stream: .* FOUND$/) {
	#		event($time, 'virus');
	#	}
	#}
	elsif ($prog eq 'smtp-vilter') {
		if ($text =~ /clamd: found/) {
			event($time, 'virus');
		}
	}
	elsif($prog eq 'avmilter') {
		# AntiVir Milter
		if($text =~ /^Alert!/) {
			event($time, 'virus');
		}
		elsif($text =~ /blocked\.$/) {
			event($time, 'virus');
		}
	}
	elsif($prog eq 'bogofilter') {
		if($text =~ /Spam/) {
			event($time, 'spam');
		}
	}
	elsif($prog eq 'filter-module') {
		if($text =~ /\bspam_status\=(?:yes|spam)/) {
			event($time, 'spam');
		}
	}
	elsif($prog eq 'sta_scanner') {
		if($text =~ /^[0-9A-F]+: virus/) {
			event($time, 'virus');
		}
	}
}

sub event {
	my ($t, $type) = @_;
	update($t) && $sum{$type}++;
}

# returns 1 if $sum should be updated
sub update($) {
	my $t = shift;
	my $m = $t - $t % RRD_STEPPING;
	$this_minute = $m unless defined $this_minute;
	return 1 if $m == $this_minute;
	return 0 if $m < $this_minute;

	my $data = '';
	for (sort keys %sum) {
		$data .= "$this_minute.mail.traffic.$_ $sum{$_}\n";
	}
	warn $data if DEBUG;

	my $ua = LWP::UserAgent->new(agent => $0);
	my $resp = $ua->request(
			HTTP::Request::Common::POST(
				RRD_SERVER_URL,
				Content_Type => 'text/plain',
				Content => $data
			)
		);
	if ($resp->is_success) {
		printf("%s\n",$resp->content);
	} else {
		warn 'Posting Error: '.$resp->status_line;
	}

	$this_minute   = $m;
	$sum{$_} = 0 for keys %sum;
	return 1;
}

__END__

