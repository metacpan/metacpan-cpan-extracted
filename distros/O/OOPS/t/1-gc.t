#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter Test::MultiFork :inactivity Clone::PP);
use OOPS;
use OOPS::GC;
use OOPS::TestCommon;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;
use Digest::MD5 qw(md5_hex);
use Clone::PP qw(clone);
use Test::MultiFork qw(stderr bail_on_bad_plan);

die $Test::MultiFork::VERSION unless $Test::MultiFork::VERSION >= 0.7;

BEGIN	{
	if ($DBD::SQLite::VERSION >= 1.0 && $ENV{HARNESS_ACTIVE}) {
		print "1..0 # Skip DBD::SQLite 1.x is likely to fail this\n";
		exit;
	}
}

$OOPS::transaction_maxtries = 120;
$OOPS::transaction_failure_maxsleep = 15;

my $sleeptime = 5;
my $batchsize = 10;
my $runlength = 2;

my %mins = (
	gcpasses	=> $runlength * 3,
	gccleaned	=> $runlength * 10,
	addpasses	=> $runlength * 10,
	deletepasses	=> $runlength * 10,
	gcspilltimes	=> $runlength,
	gcspillcount	=> $runlength * 2,
	overflowcount	=> $runlength,
	readsavedcount	=> $runlength,
);

my $common;
$debug = 1;


sub checkerror
{
	return unless $@;
	my $x = $@;
	$x =~ s/\n/  /g;
	print "\nBail out! -- '$x'\n";
}

# 
# simple test of transaction()
#

my $counter = 1;

nocon;

FORK_a4d3g2i:
#FORK_a4d3g2i:

adg:
	my ($oname, $letter, $number) = procname();
a:
	procname("add-$number");
d:
	procname("delete-$number");
g:
	procname("gc-$number");

	$OOPS::GC::too_many_todo = 200;
	$OOPS::GC::work_length = 75;
	$OOPS::GC::virtual_hash_slice = 8;
	$OOPS::GC::max_scale_factor = 100;

adg:
	my ($name) = procname();

i:
	rcon;
	eval {
		transaction(sub {
			$r1->{named_objects}{root} = {
				senders		=> (bless {}, 'Quarantine::Senders'),
				headers		=> (bless {}, 'Quarantine::Headers'),
				bodies		=> (bless {}, 'Quarantine::Bodies'), 
				buckets		=> (bless {}, 'Quarantine::Buckets'),
				recipients	=> (bless {}, 'Quarantine::Recipients'),
			};
			$r1->commit;
		});
	};
	checkerror();
	nocon;

	lockcommon;
	setcommon({ 
		gcpasses	=> 0, 
		gccleaned	=> 0,
		addpasses	=> 0,
		deletepasses	=> 0,
		gcspilltimes	=> 0,
		gcspillcount	=> 0,
		overflowcount	=> 0,
		readsavedcount	=> 0,
		alldone		=> 0,
	});
	unlockcommon;
adg:

	for(;;) {
		nocon;
		if ($letter eq 'a' || $letter eq 'd') {
			my $over;
			eval {
				transaction(sub {
					rcon;
					my $root = $r1->{named_objects}{root};
					for my $i (1..$batchsize) {
						$counter++;
						if ($letter eq 'a') {
							add_message($root, "Fred $i", "John $i", "Sub $counter $$", "Body $counter");
							add_message($root, "Ginger $i", "John $i", "Sub $counter $$", "Body $counter");
							add_message($root, "Sally $i", "John $i", "Sub $counter $$", "Body $counter");
						} elsif ($letter eq 'd') {
							delete_message($root, 2);
						} else {
							die;
						}
					}
					delete $root->{senders};
					$root->{senders} = (bless {}, 'Quarantine::Senders');
					$r1->commit;

					banner("finished $name pass");

					lockcommon();
					my ($common) = getcommon;
					if ($letter eq 'a') {
						$common->{addpasses}++;
						$over = $common->{addpasses} > $mins{addpasses} ? $over : 0;
					} else {
						$common->{deletepasses}++;
						$over = $common->{deletepasses} > $mins{deletepasses} ? $over : 0;
					}
					for my $thing (keys %mins) {
						next if $thing =~ /passes$/;
						next if $common->{$thing} >= $mins{$thing};
						$over = 0;
						last;
					}
					if ($r1->{gcspillcount}) {
						$common->{gcspilltimes}++;
						$common->{gcspillcount} += $r1->{gcspillcount};
					}
					setcommon($common);
					unlockcommon();
				});
			};
			checkerror();
			if ($over) {
				my $st = 1+int($over*$over);
				print "# sleeping for $st to let other things run\n";
				sleep($st);
			}
		} else {
			my $cleaned;
			eval {
				$OOPS::GC::readsaved_count = 0;
				$OOPS::GC::overflow_count = 0;
				$cleaned = gc(%args);
			};
			checkerror();
			my ($common) = getcommon;
			my $passes = $common->{gcpasses};
			if ($OOPS::GC::error) {
				sleepuntil(sub {
					my ($common) = getcommon;
					$common->{gcpasses} > $passes;
				});
				my $x = $OOPS::GC::error; # use it again
			} else {
				banner("finished gc pass");

				lockcommon();
				$common = getcommon;
				$common->{gcpasses}++;
				$common->{gccleaned} += $cleaned;
				if ($OOPS::GC::readsaved_count) {
					$common->{readsavedcount}++;
				}
				if ($OOPS::GC::overflow_count) {
					$common->{overflowcount}++;
				}
				my $done = 1;
				for my $thing (keys %mins) {
					if ($common->{$thing} >= $mins{$thing}) {
						print "#     DONE $thing: $common->{$thing}\n";
					} else {
						print "# NOT DONE $thing: $common->{$thing} ($mins{$thing})\n";
						$done = 0;
					}
				}
				if ($done) {
					banner("all done");
					$common->{alldone} = 1;
				}
				setcommon($common);
				unlockcommon($common);
			}
		}
		my $com = getcommon;
		last if $com->{alldone};
	}


print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "1..$okay\n";

exit 0; # ----------------------------------------------------

sub sleepuntil
{
	my ($sub) = @_;
	print "going to sleep...\n";
	for(;;) {
		sleep($sleeptime);
		return if &$sub();
		print "still sleeping...\n";
	}
}

sub init
{
	my ($ref, $default) = @_;
	$$ref = $default
		unless $$ref;
	return $$ref;
}

sub add_message
{
	my ($root, $from, $to, $header, $body) = @_;
	my $uniq = md5_hex($from . $to . $header . $body);
	my $sender = init(\$root->{senders}{$from}, (bless {
		From		=> $from,
		messages	=> (bless {}, 'Quarantine::SMessages'),
		}, 'Quarantine::Sender'));
	my $recipient = init(\$root->{recipients}{$to}, (bless {
		To		=> $to,
		messages	=> (bless {}, 'Quarantine::RMessages'),
		}, 'Quarantine::Recipient'));
	my $bodyobj = init(\$root->{bodies}{md5_hex($body)}, (bless {
		body		=> $body,
		headers		=> (bless {}, 'Quarantine::BHeaders'),
		sender		=> $sender,
		}, 'Quarantine::Body'));
	my $headerobj = bless {
		sender		=> $sender,
		recipients	=> (bless [ $recipient ], 'Quarantine::RList'),
		body		=> $bodyobj,
		header		=> $header,
		uniq		=> $uniq,
		}, 'Quarantine::Header';
	my $b1 = init(\$root->{buckets}{substr($uniq, 0, 1)}, (bless {
		}, 'Quarantine::Bucket1'));
	my $b2 = init(\$b1->{substr($uniq, 1, 1)}, (bless {
		$uniq		=> $headerobj,
		}, 'Quarantine::Bucket2'));
	$sender->{messages}{$uniq} = $headerobj;
	$recipient->{messages}{$uniq} = $headerobj;
	$bodyobj->{headers}{$uniq} = $headerobj;
}

sub delete_message
{
	my ($root, $count) = @_;
	my $buckets = $root->{buckets};
	my ($b1key) = sort keys %$buckets;
	return unless defined $b1key;
	my $b1 = $buckets->{$b1key};
	my ($b2key, $more) = sort keys %$b1;
	return unless defined $b2key;
	my $b2 = $b1->{$b2key};
	my (@uniq) = sort keys %$b2;
	while (@uniq && --$count > 0) {
		my $uniq = shift(@uniq);
		my $h = $b2->{$uniq};
		delete $b2->{$uniq};
		for my $recipient (@{$h->{recipients}}) {
			delete $recipient->{messages}{$uniq};
		}
		my $body = $h->{body};
		delete $body->{sender};
		delete $body->{headers}{$uniq};
		delete $h->{body};
		delete $h->{recipients};
	}
	if (! @uniq) {
		delete $b1->{$b2key};
		print "# deleting bucket $b1key/$b2key\n";
		if (! $more) {
			delete $buckets->{$b1key};
			print "# deleting bucket $b1key\n";
		}
	}
}

sub banner
{
	my $msg = shift;
	print "####################################################################\n";
	print "# $msg\n";
	print "####################################################################\n";
}


1;
