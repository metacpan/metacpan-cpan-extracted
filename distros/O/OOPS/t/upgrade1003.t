#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter :mysql :pg :sqlite :slow Data::Dumper Clone::PP);
use OOPS::TestCommon;
use strict;
use warnings;
use diagnostics;
use Clone::PP qw(clone);
use Data::Dumper;

our $oldver;
$oldver = 1003 unless defined $oldver;

require "OOPS/OOPS$oldver.pm";
eval " OOPS::OOPS${oldver}->import; ";
die $@ if $@;
use strict;

my $debug = 1;

print "1..459\n";

sub selector {
	my $number = shift;
	return 1 if 1; # $number > 3;
	return 0;
}

my $tests = <<'END';
	$root->{xy} = \$root->{akey}
	---
	delete $root->{hkey}
END

delete $ENV{OOPS_UPGRADE};
my $x;
supercross2($tests, {
		skey => 'sval' x 75,
		rkey => \$x,
		akey => [ 'hv1' x 100 ],
		hkey => { skey2 => 'sval2' x 150 },
	}, \&selector);
	

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;


sub supercross2
{
	my ($tests, $baseroot, $selector) = @_;
	my $number = 0;
	for my $test (split(/^\s*$/m, $tests)) {
		$number++;
		next unless &$selector($number);
		my %conf;
		$test =~ s/\A[\n\s]+//;
		$conf{$1} = [ split(' ', $2) ]
			while $test =~ s/([A-Z])=(.*)\n\s*//;
		my (@tests) = split(/\n\s+---\s*\n/, $test);
		my (@func);
		for my $t (@tests) {
			eval "push(\@func, sub { my (\$root, \$subtest, \$subtest2, \$subtest3) = \@_; $t })";
			die "eval test $number: <<$t>>of<$test>: $@" if $@;
		}
		my $pre;
		if ($conf{E}) {
			eval "\$pre = sub { my \$root = shift; @{$conf{E}} }";
			die "eval <<@{$conf{E}}>>of<$test>: $@" if $@;
		}

		my (@virt) = defined $conf{V}
			? @{$conf{V}}
			: (qw(0 virtual));
		my (@commits) = defined $conf{C}
			? (grep {$_ <= (2**@tests)} @{$conf{C}})
			: (0..2**(@tests));
		my (@ss) = defined $conf{S}
			? (grep {$_ <= (2**(@tests -1))} @{$conf{S}})
			: (0..2**(@tests -1));
		my (@subtest) = defined $conf{T}
			? @{$conf{T}}
			: (0);
		my (@subtest2) = defined $conf{U}
			? @{$conf{U}}
			: (0);
		my (@subtest3) = defined $conf{X}
			? @{$conf{X}}
			: (0);

		my $mroot = {};
		my $proot;
		for my $vobj (@virt) {
			for my $subtest (@subtest) {
				for my $subtest2 (@subtest2) {
					for my $subtest3 (@subtest3) {
						for my $docommit (@commits) {
							for my $du (0..count_bits($docommit)) {
								for my $dosamesame (@ss) {
									my $do_upgrade = $du;
									nocon;
									no strict qw(refs);
									print "# ---------------------------- reset all ---------------------- \n";
									&{"OOPS::OOPS${oldver}::initial_setup"}("OOPS::OOPS${oldver}", %args) || die;
									use strict;
									delete $args{auto_upgrade};
									rcon;
									test($r1->{arraylen}{1} == $oldver);
									my $x = 'rval';
									$mroot = clone($baseroot);
#print Dumper(__LINE__, 'mroot', $mroot);
									&$pre($mroot) if $pre;

									$r1->{named_objects}{root} = clone($mroot);
									$r1->virtual_object($r1->{named_objects}{root}, $vobj) if $vobj;
									$r1->virtual_object($r1->{named_objects}{root}{hkey}, $vobj) if $vobj;
									$r1->commit;
									upgrade($do_upgrade);

									my $sig = "N=$number.V=$vobj.C=$docommit.S=$dosamesame.T=$subtest.U=$subtest2.X=$subtest3";
									print "# $sig\n";
									print $test if $debug;

									for my $tn (0..$#func) {
										my $tf = $func[$tn];
										$proot = $r1->{named_objects}{root};
#print Dumper(__LINE__, 'proot', $proot);

										print "# EXECUTING $tests[$tn]\n" if $debug;
										&$tf($proot,$subtest,$subtest2,$subtest3);
#print Dumper(__LINE__, 'proot', $proot);

										&$tf($mroot,$subtest,$subtest2,$subtest3);
#print Dumper(__LINE__, 'mroot', $mroot);

										$r1->commit
											if $docommit & 2**$tn;
										print "# COMPARING\n" 
											if $dosamesame & 2**$tn && $debug;

#print Dumper(__LINE__, 'proot', $proot);
#print Dumper(__LINE__, 'mroot', $mroot);

										test(docompare($mroot, $proot), "<$tn>$sig")
											if $dosamesame & 2**$tn;
										upgrade($do_upgrade)
											if $tn < $#func && $docommit & 2**$tn;
									}
									print "# FINAL COMPARE\n" if $debug;
									test(docompare($mroot, $proot), "<END>$sig");
									test($r1->{arraylen}{1} == $OOPS::SCHEMA_VERSION);
								}
							}
						}
					}
				}
			}
		}

		rcon;

		nukevar($r1->{named_objects}, $mroot);
		$r1->commit;
		rcon;
		notied;
	}
}

sub upgrade
{
	print "# ugprade? $_[0]\n";
	if ($_[0]-- == 0) {
		test($r1->{arraylen}{1} == $oldver);
		$args{auto_upgrade} = 1;
		print "# UPGRADING from $oldver to $OOPS::SCHEMA_VERSION\n";
		rcon;
		test($r1->{arraylen}{1} == $OOPS::SCHEMA_VERSION);
	} else {
		print "# Not upgrading\n";
		rcon;
	}
}

sub count_bits
{
	my $x = shift;
	my $bits = 0;
	while ($x) {
		$bits++ if $x & 1;
		$x <<= 1;
	}
#print "bits for $_[0] = $bits\n";
	return $bits;
}
