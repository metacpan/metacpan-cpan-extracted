#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter Clone::PP);
use OOPS;
use OOPS::GC;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;
use Digest::MD5 qw(md5_hex);
use OOPS::TestCommon;

print "1..2423\n";

my $common;
$debug = 0;

my $size = 1000;
my $stride = 20;
my $maxpass = $size / $stride + 2;

resetall;

my $c = "ab001";
my $pstuff = $fe->{stuff} = {};
my $mstuff = {};

for my $i (1..$size) {
	$mstuff->{$c} = $pstuff->{$c} = $i;
	$c++;
}
my $undef = undef;
{
	no warnings;
	$mstuff->{$undef} = $pstuff->{$undef} = 'undef!';
}
$mstuff->{'undef'} = $pstuff->{'undef'} = $undef;
$mstuff->{''} = $pstuff->{''} = 'empty';
$mstuff->{empty} = $pstuff->{empty} = '';

$fe->virtual_object($pstuff,1);

$fe->commit;

rcon;

test($fe->virtual_object($fe->{stuff}), "virtual?");

test(docompare($mstuff, $fe->{stuff}), "mstuff, pstuff");

use OOPS::TxHash;

for my $getstuff ('$stuff = $fe->{stuff}', '$stuff = $mstuff') {

	my %real_todo = ( stuff => undef );
	my %got = ();
	my $passes = 0;
	while (%real_todo) {
		nocon;
		test($passes < $maxpass, "pass count $getstuff");
		transaction(sub {
			my $th = tie my %todo, 'OOPS::TxHash', \%real_todo or die;
			rcon;
			# my $oops = OOPS->new(...);
			my $stuff;
			eval $getstuff;

			if (exists $todo{stuff}) {
				print "# calling walkhash($getstuff, $stride, $todo{stuff}\n" if $debug;
				my @keys = walk_hash(%$stuff, $stride, $todo{stuff});

				test(@keys <= $stride, "stride length $getstuff");
				for my $k (@keys) {
					my $display = defined $k ? $k : 'UNDEF';
					print "# got <$display> from $getstuff\n" if $debug;
					test(! exists $got{$k}, "exists <$display> $getstuff");
					$got{$k} = $stuff->{$k};
				}

				my $x = $keys[$#keys];
				$todo{stuff} = $x;
				print "# Setting todo{stuff} = '$x'\n";
				delete $todo{stuff} unless @keys == $stride;
			}

			test(docompare(\%got, $stuff), "$getstuff, got") unless exists $todo{stuff};

			$fe->commit;
			$th->commit;
		});
	}
}



print "# ---------------------------- done ---------------------------\n" if $debug;

exit 0; 

1;
