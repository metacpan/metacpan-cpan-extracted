#!/usr/bin/perl -I../lib

my $dbi_trace_turnon = 9999999999;
my $dbi_trace_level = 0;

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:slow :filter :sqlite Data::Dumper Clone::PP);
use OOPS;
require Carp::Heavy;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use OOPS::TestCommon;
use Clone::PP qw(clone);

my $skipto = 0; # go directly to test number...

print "1..7356\n";
my $debug2 = 0;
my $debug3 = 0;

resetall; # --------------------------------------------------
{
	my $realdebug = $debug;
	my $failures = <<'END';
END
	#
	# flags:
	#
	#	V - try with virtual object and regular object
	#	h - set $key to various keys a hash might use
	#	a - set $key to various index an array might use
	#	v - replace $pval with potential values
	#
	my $tests = <<'END';
		Vhv- $root->{$key} = $pval

END
	my %failures;
	for my $failure (split(/\n/, $failures)) {
		$failure =~ s/^\s+//;
		$failure =~ s/\s+$//;
		$failures{$failure} = 1;
		print "# adding '$failure'\n" if $debug2;
	}
	for my $test (split(/^\s*$/m, $tests)) {
		$test =~ s/\s*(\S*)-\s//s;
		my $flag = $1;

		my (@virt) = $flag =~ /V/
			? (qw(
				virtual
			))
			: (0);
		my (@key) = (0);

		if ($flag =~ /h/) {
			@key = (qw(
				'x'
				'x'
				'x'
				'x'
				'x'
				'x'
				'x'
			));
		} elsif ($flag =~ /a/) {
			@key = (0..7);
		} 


		no warnings qw(syntax);
		my (@val) = $flag =~ /v/
			? (qw( 
				'y'
				'y'
				'y'
				'y'
				'y'
				'y'
				'y'
			))
			: ( '1' );
		use warnings;

		my @skips = (qw(10 00 01 11));
		my @groups = ('onegroup', '', 'manygroups');

		my $nodata_per_loop = count(grep(! /root/, @val)) / scalar(@val);
		my $skippre_per_loop = count(grep(substr($_, 0, 1), @skips)) / scalar(@skips);
		my $skippost_per_loop = 2 * count(grep(substr($_, 1, 1), @skips)) / scalar(@skips);
		my $loops = scalar(@val) * scalar(@key) * scalar(@groups) * scalar(@virt) * scalar(@skips);
		my $base_per_loop = 
			3					# resetall
			+ 2 * 2					# rcon
			+ (($flag =~ /V/) ? 1 : 0)		# test vobj
			+ 1					# test unconditional
			+ 1					# notied
			;
		my $per_loop = $base_per_loop + $skippre_per_loop + $skippost_per_loop;
#		printf "# per_loop = %d ( 9 + flag:%s + pre:%s + post:%s + nodata:%s )\n",
#			$per_loop,  
#			(($flag =~ /V/) ? 1 : 0),
#			$skippre_per_loop,
#			$skippost_per_loop,
#			$nodata_per_loop;
		my $expected = $okay + $loops * ($per_loop + $nodata_per_loop);
		if ($expected < $skipto) {
			$okay = $expected;
			next;
		}

		for my $val (@val) {
			$nodata_per_loop = ($val =~ /root/) ? 0 : 1;
			my $loops = scalar(@key) * scalar(@groups) * scalar(@virt) * scalar(@skips);
			my $expected2 = $okay + $loops * ($per_loop + $nodata_per_loop);
			if ($expected2 < $skipto) {
				$okay = $expected2;
				next;
			}

			for my $key (@key) {
				my $loops = scalar(@groups) * scalar(@virt) * scalar(@skips);
				my $expected3 = $okay + $loops * ($per_loop + $nodata_per_loop);
				if ($expected3 < $skipto) {
					$okay = $expected3;
					next;
				}

				my $sub; 
				my $e = <<END;
					\$sub = sub { 
						my \$z = 'ov09'x($ocut/4+1);
						my \$root = shift; 
						my \$pval = $val;
						my \$key = $key;
						no warnings;
						$test
					}
END

				eval $e;
				die "on $test/$val/$key ... <<$e>> ... $@" if $@;

				for my $skips (@skips) {
					my $skippre = substr($skips, 0, 1);
					my $skippost = substr($skips, 1, 1);

					my $loops = scalar(@groups) * scalar(@virt);
					my $per_loop2 = $base_per_loop + $nodata_per_loop
						+ ($skippre ? 0 : 1)
						+ ($skippost ? 0 : 2);
					my $expected4 = $okay + $loops * $per_loop2;
					if ($expected4 < $skipto) {
						$okay = $expected4;
						next;
					}

					for my $groupmangle (@groups) {

						my $loops = scalar(@virt);
						my $expected5 = $okay + $loops * $per_loop2;
						if ($expected5 < $skipto) {
							$okay = $expected5;
							next;
						}

						for my $vobj (@virt) {

							my $expected6 = $okay + $per_loop2;
							if ($expected6 < $skipto) {
								$okay = $expected6;
								next;
							}
							if ($expected6 >= $dbi_trace_turnon) {
								$OOPS::debug_dbi = $dbi_trace_level;
							}
							my $preok = $okay;

							resetall;

							die if $debug && $okay != $preok + 3;

							my $desc = "$flag- $test: key=$key val=$val V$vobj.S$skippre$skippost.G$groupmangle";
							$desc =~ s/\A\s*(.*?)\s*\Z/$1/s;
							$desc =~ s/\n\s*/\\n /g;
							$debug = $failures{$desc}
								? 0
								: $realdebug;
							print "# desc='$desc' debug=$debug\n";

							print "# $desc\n" if $debug;

							my $rv = "x\000x";
							my $x = chr(0)x($ocut+1);
							my $mroot = {
								# the length of this array should match the flag =~ /a/ array size of @key (above).
								'' => { skey2 => 'sval2' },
								undef => "0 but true",
								"0" => [ qw(
									''
									undef
									"0\000"
									"0"
									chr(0)
									"With\000inside"
									"with\\back"
									), '"0 but true"' ],
								"0 but true" => \$rv,
								"0\000" => \[ undef, "0", chr(0) ],
								chr(0) => \{ chr(0) => undef},
#								"With\000inside" => \ (scalar(chr(0)x($ocut+1))),
#XXX								"with\\back" => \$x,
#XXX								"witH\\back" => \$x,
							};

							$r1->{named_objects}{root} = clone($mroot);
							$r1->virtual_object($r1->{named_objects}{root}, $vobj) if $vobj;
							$r1->commit;
							nocon;
							if ($groupmangle) {
								groupmangle($groupmangle);
							}
							rcon;
							die if $debug && $okay != $preok + 3 + 2;

							print "#PROGRESS: BEFORE $desc\n" if $debug2;

							my $proot = $r1->{named_objects}{root};

							test(docompare($mroot, $proot), $desc) unless $skippre;

							die if $debug && $okay != $preok + 3 + 2 + ($skippre ? 0 : 1);

							print "mroot before: ".Dumper($mroot)."\n" if $debug3;

							&$sub($mroot);

							print "mroot after: ".Dumper($mroot)."\n" if $debug3;
							print "#PROGRESS: PRE CHANGES: $desc\n" if $debug2;
							print "proot before: ".Dumper($proot)."\n" if $debug3;

							print "# EXECUTING: $desc\n" if $debug;

							&$sub($proot);

							print "#PROGRESS: POST CHANGES: $desc\n" if $debug2;
							print "proot after: ".Dumper($proot)."\n" if $debug3;
							print "#PROGRESS: PRE COMPARE: $desc\n" if $debug2;

							test(docompare($mroot, $proot), $desc) unless $skippost;

							die if $debug && $okay != $preok + 3 + 2 + ($skippre ? 0 : 1) + ($skippost ? 0 : 1);

							print "#PROGRESS: POST COMPARE, PRE COMMIT: $desc\n" if $debug2;

							$r1->commit;

							print "#PROGRESS: POST COMMIT, PRE COMPARE#2: $desc\n" if $debug2;

							test(docompare($mroot, $proot), $desc) unless $skippost;

							die if $debug && $okay != $preok + 3 + 2 + ($skippre ? 0 : 1) + ($skippost ? 0 : 2);

							print "#PROGRESS: POST COMPARE#2, PRE RECONNECT: $desc\n" if $debug2;

							undef $proot;
							rcon;
# our $xy = 1;
							die if $debug && $okay != $preok + 3 + 2 + ($skippre ? 0 : 1) + ($skippost ? 0 : 2) + 2;

							my $qroot = $r1->{named_objects}{root};

							print "#PROGRESS: POST RECONNECT, PRE COMPARE #3: $desc\n" if $debug2;

							test(docompare($mroot, $qroot), $desc);
							die if $debug && $okay != $preok + 3 + 2 + ($skippre ? 0 : 1) + ($skippost ? 0 : 2) + 2 +1;

							print "#PROGRESS: POST COMPARE #3, PRE DELETES: $desc\n" if $debug2;

							test(!$vobj == !$r1->virtual_object($qroot), $desc) if $flag =~ /V/;
							die if $debug && $okay != $preok + 3 + 2 + ($skippre ? 0 : 1) + ($skippost ? 0 : 2) + 2 + 1 + (($flag =~ /V/) ? 1 : 0);

							nukevar($qroot, $mroot);
							delete $r1->{named_objects}{root};

							print "#PROGRESS: POST DELETES, PRE COMMIT: $desc\n" if $debug2;

							$r1->commit;

							print "#PROGRESS: FINAL COMMIT DONE: $desc\n" if $debug2;

							undef $qroot;
							nocon;

							nodata unless $val =~ /root/;
							die if $debug && $okay != $preok + 3 + 2 + ($skippre ? 0 : 1) + ($skippost ? 0 : 2) + 2 + 1 + ($flag =~ /V/ ? 1 : 0) + (($val =~ /root/) ? 0 : 1);
							notied($desc);
							die if $debug && $okay != $preok + 3 + 2 + ($skippre ? 0 : 1) + ($skippost ? 0 : 2) + 2 + 1 + ($flag =~ /V/ ? 1 : 0) + (($val =~ /root/) ? 0 : 1) + 1;

							print "#PROGRESS: DONE WITH TEST: $desc\n" if $debug2;

							print "# okay: $okay expected6: $expected6\n";
							die "bad prediction" if $debug && $okay != $expected6;
						}
						print "# okay: $okay expected5: $expected5\n";
						die "bad prediction" if $debug && $okay != $expected5;
					}
					print "# okay: $okay expected4: $expected4\n";
					die "bad prediction" if $debug && $okay != $expected4;
				}
				print "# okay: $okay expected3: $expected3\n";
				die "bad prediction" if $debug && $okay != $expected3;
			}
			print "# okay: $okay expected2: $expected2\n";
			die "bad prediction" if $debug && $okay != $expected2;
		}
		print "# okay: $okay expected: $expected\n";
		die "bad prediction" if $debug && $okay != $expected;

	}
	$debug = $realdebug;
}

resetall; # --------------------------------------------------
print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

sub count
{
	return scalar(@_);
}

1;

