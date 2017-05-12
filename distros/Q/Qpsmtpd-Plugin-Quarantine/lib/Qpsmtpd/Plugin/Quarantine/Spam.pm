# Copyright(C) 2006 David Muir Sharnoff <muir@idiom.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# This software is available without the GPL: please write if you need
# a non-GPL license.  All submissions of patches must come with a
# copyright grant so that David Sharnoff remains able to change the
# license at will.


package Qpsmtpd::Plugin::Quarantine::Spam;

use Qpsmtpd::Constants;
use Qpsmtpd::DSN;
use File::Slurp;
use Qpsmtpd::Plugin::Quarantine::Common;

our @ISA = qw(Exporter);
our @EXPORT = qw(check_message_for_spam spam_init);

use strict;

my @spamd3;
my $headerrx = qr/\G(\S+):((?:.+(?=\n)|\n(?=\s))+)?\n/;
my %spamc_headers = (
	'X-Spam-Status' => 1,
	'X-Spam-Report' => 1,
);

# -----------------------------------------------------------------------


tie my %q_shell, 'FuncT', sub {
		my $file = shift;
		return $file if $file =~ /^[-_\.+=:\/0-9a-zA-Z]+$/;
		$file =~ s/'/'\\''/g;
		"'$file'";
	};

my $myhostname = $Qpsmtpd::Plugin::Quarantine::Spam::myhostname;

# -----------------------------------------------------------------------

sub spam_init
{
	my $total = 0;
	map { $total += $defaults{spamd3}{$_} } keys %{$defaults{spamd3}};
	my (%map) = map { $_ => rand($total)+$defaults{spamd3}{$_} } keys %{$defaults{spamd3}};
	@spamd3 = sort { $map{$b} <=> $map{$a} } keys %map;
}

sub check_message_for_spam
{
	my ($qp, $transaction) = @_;

	my $headers = $transaction->header();
	my $file = $transaction->body_filename();

	my $x = read_file($file);

	my %results;

	TEST:
	for(;;) {
		if (($defaults{clamd} || $defaults{clamav}) && 
			($headers->get('Content-Type') =~ /$defaults{virus_content}/ 
			|| $headers->get('Content-Disposition') =~ /$defaults{virus_content}/ 
			|| ($headers->get('Content-Type') =~ /multipart/
				&& $transaction->body_as_string() =~ /^Content-Type: $defaults{virus_content}/m)))
		{
			last if 
				clamav($qp, $transaction, \%results, ($defaults{clamd} || $defaults{clamav}), 'stream');
			unless (exists $results{clamav}) {
				last if
					clamav($qp, $transaction, \%results, ($defaults{clamd} || $defaults{clamav}), $file);
			}
		}

		for my $spamd3 (@spamd3) {
			last TEST if 
				spamc($qp, $transaction, \%results, $spamd3, 'SPAMASSASSIN3');
			last if $results{spamc};
		}

		last if $results{filtered};

		if ($defaults{clamd}) {
			unless (exists $results{clamav}) {
				last if
					clamav($qp, $transaction, \%results, $defaults{clamd}, 'stream');
			}
		}

		if ($defaults{clamav}) {
			unless (exists $results{clamav}) {
				last if
					clamav($qp, $transaction, \%results, $defaults{clamav}, $file);
			}
		}
		
		last;
	}
	$qp->log(LOGDEBUG, "Filtered? $results{filterd}");
	$qp->log(LOGDEBUG, "Details: $results{hlines}");
	return $results{filtered};
}

sub clamav
{
	my ($qp, $transaction, $r, $command, $input) = @_;
	my $results;
	my $file = $transaction->body_filename();
	eval {
		local($SIG{__DIE__}) = 'DEFAULT';
		local($SIG{ALRM}) = sub { 
			$qp->log(LOGWARN, "ClamAV timeout");
			die "timeout\n";
		};
		alarm($defaults{subcommand_timeout}) if $defaults{subcommand_timeout};
		$results = `$command $file`;
	};
	unless ($results =~ /-- SCAN SUMMARY --/ && $results =~ /^\Q$input\E: (OK|.*FOUND)\n/) {
		$qp->log(LOGINFO, "ClamAV failed: $results");
		$r->{clamav} = undef;
		return 0;
	}
	my $return = 0;
	my $status = $1;
	if ($status =~ /\n\n/) {
		$qp->log(LOGINFO, "ClamAV Failed: $results");
		$r->{clamav} = undef;
		return 0;
	} elsif ($status eq "OK") {
		$status = "X-ClamAV-Status: No\n";
	} else {
		$status = "X-ClamAV-Status: Yes, $status\n";
		$r->{filtered} .= " CLAMAV";
		$return = 1;
	}
	$r->{clamav} = $status;
	$r->{hlines} .= $status;
	return $return;
}

sub results_in_headers
{
	my ($qp, $transaction, $r, $command, $lookfor) = @_;
	$qp->log(LOGDEBUG, "running $command...");
	local($/) = "\n\n";
	my $file = $transaction->body_filename();
	unless (open(RESULTS, "$command < $file|")) {
		$qp->log(LOGWARN, "Could not open $command: $!");
		return '';
	}
	my $h = <RESULTS>;
	$/ = "\n";
	chomp($h);
	close(RESULTS);

	my $fileheader = $transaction->header()->as_string();
	my $fileheaderlen = length($fileheader);

	if (substr($h, 0, $fileheaderlen) eq $fileheader) {
		substr($h, 0, $fileheaderlen) = '';
	} elsif ($h =~ /^(From .*\n)/g) {
		# weird, with qpsmtpd we don't have a "From " line
	} elsif ($h =~ /^[A-Z][-\w]*:/) {
		# that's good
	} else {
		$qp->log(LOGWARN, "Could not parse output from $command");
		return '';
	}
	my $found = '';
	my %found;
	pos($h) = 0;
	while ($h =~ /$headerrx/gco) {
		my ($k, $v) = ($1, $2);
		next unless $lookfor->{$k};
		$found{$k} = $v;
		$found .= "$k:$v\n";
	}
	if (pos($h) != length($h)) {
		$qp->log(LOGWARN, "Unparsed header from $command");
		return '';
	}
	return ($found, %found);
}

sub spamc 
{
	my ($qp, $transaction, $r, $command, $tag) = @_;
	my $file = $transaction->body_filename();
	$qp->log(LOGDEBUG, "running $command...");
	my $results;
	eval {
		local($SIG{__DIE__}) = 'DEFAULT';
		local($SIG{ALRM}) = sub { 
			$qp->log(LOGWARN, "TIMEOUT $command $file");
			die "timeout\n";
		};
		alarm($defaults{subcommand_timeout}) if $defaults{subcommand_timeout};
		$results = `$command $file`;
	};
	$results =~ m!^(-?\d+\.\d+)/(\d+\.\d+)\n!;
	my ($score, $thresh) = ($1 || '', $2 || '');
	unless ($thresh && $thresh > 0 && ($results =~ s/.*^[- ]{25,300}\n//sm)) {
		$results = substr($results, 0, 30);
		$results =~ s/\n/\\n/g;
		$qp->log(LOGDEBUG, "'$command $file' failed $thresh: $results");
		return '';
	}
	my @tests;
	my $report = '';
	$thresh = 5.0;
	while ($results =~ /\G {0,5}(-?\d+(?:\.\d+)?) (\S+)\s+(\S(?:.+(?=\n)|\n(?= {6}))+)\n/g) {
		my ($pts, $rule, $desc) = ($1, $2, $3);
		$desc =~ s/\n {5,60}(\S)/\n\t*      $1/g;
		push(@tests, $rule);
		$report .= sprintf("\t* % 4s %s %s\n", $pts, $rule, $desc);
	}
	my $xss;
	my $tests = join(',', @tests);
	if ($score >= $thresh) {
		$xss = "X-Spam-Status: Yes, hits=$score required=$thresh tests=$tests\n";
		$r->{filtered} .= " $tag";
		$report = "X-Spam-Report:\n$report";
	} else {
		$xss = "X-Spam-Status: No, hits=$score required=$thresh tests=$tests\n";
		$report = "";
	}
	1 while $xss =~ s/^(.{60}.*?,)(?=.)/$1\n\t/m;
	my $rout = "$xss$report";
	if ($rout =~ /\n\n/) {
		$qp->log(LOGWARN, "$command $file: failed doubleNL $results");
		return '';
	}
	$r->{spamc} = $rout;
	$r->{hlines} .= $rout;
	return $report;
}

1;
