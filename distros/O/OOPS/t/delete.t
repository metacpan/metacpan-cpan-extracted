#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter :slow);

package OOPS::Test::delete;

use OOPS;
use OOPS::TestCommon;
use OOPS::GC;
use OOPS::Fsck;
require OOPS::Setup;
use strict;
use warnings;
use diagnostics;
use Digest::MD5 qw(md5_hex);

print "1..363\n";

sub selector {
	my $number = shift;
	return 1 if 1; # $number > 3;
	return 0;
}

my $FAIL = <<'END';
END

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
		delete $h->{body}{headers}{$uniq};
		delete $h->{sender}{messages}{$uniq};
		for my $recipient (@{$h->{recipients}}) {
			delete $recipient->{messages}{$uniq};
		}
		%$h = ();
	}
	if (! @uniq) {
		delete $b1->{$b2key};
		if (! $more) {
			delete $buckets->{$b1key};
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


my $tests = sprintf("# %d \"%s\"\n", __LINE__, __FILE__).<<'END';
	# my $size = 50;
	my $size = 25;
	#my $size = 10;

	my $linterrors;

	banner "initial gc test";
	BEGIN TRANSACTION
		%$root = ();
		$root->{baz} = { keeper => 7 };
		$root->{foo} = { bar => 88, root => $root, baz => $root->{baz} };
		$root->{bar} = { foo => $root->{foo} };
		$root->{foo}{bar} = $root->{bar};
		COMMIT
	END TRANSACTION

	my $gcremoved = gc(%args);
	test($gcremoved == 0, "GC removed == $gcremoved");

	BEGIN TRANSACTION
		delete $root->{foo};
		delete $root->{bar};
		COMMIT
	END TRANSACTION

	# $OOPS::GC::debug = 99;

	$gcremoved = gc(%args);
	test($gcremoved == 2, "GC removed == $gcremoved");

	banner "initialize";
	BEGIN TRANSACTION
		%$root = (
			senders		=> (bless {}, 'Quarantine::Senders'),
			headers		=> (bless {}, 'Quarantine::Headers'),
			bodies		=> (bless {}, 'Quarantine::Bodies'), 
			buckets		=> (bless {}, 'Quarantine::Buckets'),
			recipients	=> (bless {}, 'Quarantine::Recipients'),
		);
		COMMIT
	END TRANSACTION
	banner "virtualize";
	transaction (sub {
		rcon;
		my $proot = $r1->{named_objects}{root};
		die unless $proot;
		$r1->virtual_object($proot->{senders}, 1);
		$r1->virtual_object($proot->{recipients}, 1);
		$r1->virtual_object($proot->{bodies}, 1);
		$r1->virtual_object($proot->{buckets}, 1);
		$r1->commit;
	});
	banner "verify virutalize";
	transaction (sub {
		rcon;
		my $proot = $r1->{named_objects}{root};
		die unless $r1->virtual_object($proot->{senders});
	});
	banner "add first set";
	for my $i (2..$size) {
		my $j = int($i/5) + 1;
		BEGIN TRANSACTION
			add_message($root, "Jonny $j", "Billy $i", "Re: Stuff", "Get Lost!\nFor the ${i}th time");
			COMMIT
		END TRANSACTION
		BEGIN TRANSACTION
			add_message($root, "Jonny $j", "Fred $i", "Re: Stuff", "Get Lost!\nFor the ${i}th time");
			COMMIT
		END TRANSACTION
		BEGIN TRANSACTION
			add_message($root, "Jonny $j", "Sally $i", "Re: Stuff", "Let me count the ways.... $i");
			COMMIT
		END TRANSACTION
		if ($i % 10 == 3) {
			COMPARE
		}
	}


	COMPARE

	banner "add second set, remove some";
	for my $i (2..$size) {
		my $j = int($i/5) + 1;
		if ($i % 3 == 0) {
			BEGIN TRANSACTION
				add_message($root, "Jonny $j", "Billy $i", "I've reconsidered", "Get Lost!\nFor the ${i}th time");
				COMMIT
			END TRANSACTION
		}
		if ($i % 3 == 1) {
			BEGIN TRANSACTION
				add_message($root, "Jonny $j", "Fred $i", "Re: Stuff, again", "Get Lost!\nFor the ${i}th time");
				COMMIT
			END TRANSACTION
		}
		if ($i % 3 == 2) {
			BEGIN TRANSACTION
				add_message($root, "Jonny $j", "Sally $i", "Yea, right", "Let me count the ways.... $i");
				COMMIT
			END TRANSACTION
		}
		BEGIN TRANSACTION
			delete_message($root, 2);
			COMMIT
		END TRANSACTION
		if ($i % 10 == 3) {
			COMPARE
		}
	}

	nocon;
	banner "fsck";
	$linterrors = fsck(%args);
	test($linterrors == 0, "LINT errors == 0");

	COMPARE

	banner "add third set, remove a bunch";
	for my $i (2..$size) {
		my $j = int($i/5) + 1;
		if ($i % 3 == 0) {
			BEGIN TRANSACTION
				add_message($root, "Jonny $j", "Billy $i", "Changed again!", "Get Lost!\nFor the ${i}th time");
				COMMIT
			END TRANSACTION
		}
		BEGIN TRANSACTION
			delete_message($root, 3);
			delete_message($root, 3);
			delete_message($root, 3);
			delete_message($root, 3);
			delete_message($root, 3);
			delete_message($root, 3);
			COMMIT
		END TRANSACTION
	}

	nocon;
	banner "fsck";
	$linterrors = fsck(%args);
	test($linterrors == 0, "LINT errors == 0");

	COMPARE

	nocon;

	banner "first real gc";
	$gcremoved = gc(%args);
	test($gcremoved == 0, "GC removed == 0");

	COMPARE

	banner "remove everything, leak the old stuff";

	BEGIN TRANSACTION
		$root->{senders}{fake} = $root->{buckets};
		$root->{buckets}{fake} = $root->{recipients};
		$root->{recipients}{fake} = $root->{bodies};
		$root->{bodies}{fake} = $root->{headers};
		$root->{headers}{fake} = $root->{senders};

		%$root = (
			senders		=> (bless {}, 'Quarantine::Senders'),
			headers		=> (bless {}, 'Quarantine::Headers'),
			bodies		=> (bless {}, 'Quarantine::Bodies'), 
			buckets		=> (bless {}, 'Quarantine::Buckets'),
			recipients	=> (bless {}, 'Quarantine::Recipients'),
		);
		COMMIT
	END TRANSACTION

	COMPARE

	nocon;

	banner "second real gc";

	$gcremoved = gc(%args);

	COMPARE

	nocon;

	qcheck "select count(*) from TP_object where id > $OOPS::last_reserved_oid", <<EQCK;
		+----------+
		| count(*) |
		+----------+
		|        6 |
		+----------+
EQCK
END

my $x;
supercross8($tests, {});


print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;

