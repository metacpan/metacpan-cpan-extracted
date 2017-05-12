#!/usr/bin/perl -w

use strict;

use FreezeThaw qw (freeze thaw);
use lib '/home/steven/src';

use Net::TL1;

use Test::Simple tests => 15;

#BEGIN { plan tests => 15 }

my $debug = 0;

{
	my $tl1 = new Net::TL1({Debug => 0});

	$0 =~ /^(.*)\.t$/;
	my $file = "$1.data";
	print "File: $file\n";
	my $testref = $tl1->read_testfile($file);
	#my $testref = $tl1->read_testfile('TL1-ASAM7301-session.log');

	foreach my $key (sort keys %{$testref}) {
		my $ctag;
		if ($key =~ /:(\d{3}):+;{0,1}\s*$/) {
			$ctag = $1;
		} else {
			if ($key =~ /^\s*ACT-USER/) {
				$ctag = 100;
			} else {
				print "no ctag for $key\n";
				$ctag = 0;
			}
		}
		$debug && print ";$key\n";
	
		### Empty FreezeThaw line:
		# 102: RTRV-ALM-SERV:PR-DSLAM1:SERV-1-1-1:102:;
		# 103: RTRV-COND-SERV:PR-DSLAM1:SERV-1-1-1:103:;
		# 104: RTRV-ATTR-SERV:PR-DSLAM1:SERV:104:;
		# 105: RTRV-INV-SERV:PR-DSLAM1:SERV-1-1-1:105:;
		# 114: REPT-OPSTAT-IGMPCHN:PR-DSLAM1:IGMPUAI-1-1-2-1-0-37:114:;
		# 115: REPT-OPSTAT-IGMPMDL:PR-DSLAM1:NTIGMP:115:;
		# 116: RTRV-IGMPCHN:PR-DSLAM1:IGMPUAI-1-1-2-1-0-37:116:::;
		# 117: RTRV-IGMPLEAF:PR-DSLAM1:LEAFUAI-1-1-2-9-0-37-60:117:;
		# 118: RTRV-IGMPSYS:PR-DSLAM1:COM:118:;
		# 119: RTRV-MCSRC:PR-DSLAM1:MCSRC-235-80-0-1:119:;
		if (!grep (/$ctag/, 102, 103, 104, 105, 114, 115, 116, 117, 118, 119)){
			$tl1->Execute($key, @{$$testref{$key}{output}});
			if ($ctag == 101 || $ctag == 111 || $ctag == 112 || $ctag == 113
					|| $ctag == 121 || $ctag == 122 || $ctag == 123) {
				$tl1->ParseSimpleOutputLines($ctag);
			} else {
				$tl1->ParseCompoundOutputLines($ctag);
			}
			my $ref = $tl1->get_hashref;
			my $string = freeze ($ref);
			$debug && print "FreezeThaw $string\n";

			ok ($string eq $$testref{$key}{FreezeThaw}, $key);

		}
		if ($debug) {
			foreach my $line (@{$$testref{$key}{output}}) {
				print "$line";
			}
		}
	}
}
