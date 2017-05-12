#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter Data::Dumper :slow);
use OOPS;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;
use OOPS::TestCommon;

my $edebug;

print "1..5753\n";

resetall; # --------------------------------------------------
{
	# we're interested in sequences of ops with different 
	# kinds of values
	#
	# ops:
	#	push
	#	pop
	#	shift
	#	unshift
	#	splice - start - +1
	#	splice - start - -1
	#	splice - start - 0
	#	splice - middle - +1
	#	splice - middle - -1
	#	splice - middle - 0
	#	splice - end - +1
	#	splice - end - -1
	#	splice - end - 0
	#	fetch
	#	store - scalar
	#	store - object
	#	store - overflow
	#	extend
	#	exists
	#	size
	#	delete
	#
	#	clear
	#
	# old values:
	#	scalar
	#	ref
	#	overflow
	#	undef
	#	
	# 3 op sequences:
	#	op1 op2 op3
	#


	my $t1 = sub {
		my $named = shift;
		my (@iv1) = @{shift()};
		my (@iv2) = @{shift()};
		my (@op1) = @{shift()};
		my (@op2) = @{shift()};
		my (@op3) = @{shift()};
		my $root = $named->{root} = {};
		my $i;
	#print "SCALR ARRAY $a now $#$a long\n";
	#print join('',(map { exists $a->[$_] ? '1' : '0' } 0..$#$a),"\n");
		my (@IVtext) = split(/^\s+(\w):[\n\s]+/m, <<'END');
			s:
				$a->[$j] = "s$j";
				$a->[$j+1] = "s$j+";
			o:
				$a->[$j] = { $k => "$i.$j" };
				$a->[$j+1] = { $k => "$i.$j+" };
			O:
				$a->[$j] = "$k-$i-$j-" x ($ocut / length("$k-$i-$j-") + 1);
				$a->[$j+1] = "$k-$i-$j+" x ($ocut / length("$k-$i-$j-") + 1);
			u:
				$a->[$j] = undef;
				$a->[$j+1] = undef;
			e:
				$#$a = $j+1;
END
		#print join("\n---------------\n", @IVtext);
		#print "\n";
		shift(@IVtext) unless $IVtext[0] =~ /\w/;
		my (%IVtext) = @IVtext;
		my %IV;
		for my $iv (keys %IVtext) {
			eval " \$IV{\$iv} = sub { my (\$a, \$k, \$j, \$i) = \@_; $IVtext{$iv} }; ";
			die "eval <<$IVtext{$iv}>>: $@" if $@;
		}
		for my $op1 (@op1) {
			for my $iv1 (@iv1) {
				for my $op2 (@op2) {
					for my $iv2 (@iv2) {
						for my $op3 (@op3) {
							my $k = "$iv1.$iv2.$op1.$op2.$op3";
							$i++;
							my @a;
							my $j = 0;
							for my $iv ($iv1, $iv2) {
								my $ivsub = $IV{$iv} || die "no initializer '$iv'";
								print "# $IVtext{$iv}\n" if $debug && $Npossible == 1 && $Nvert;
								&$ivsub(\@a, $k, $j, $i);
								$j += 2;
							}
							$root->{$k} = \@a;
						}
					}
				}
			}
		}
	};
	#print "SCALR ARRAY $ar now $#$a long\n";
	#print join('',(map { exists $ar->[$_] ? '1' : '0' } 0..$#$ar),"\n");
	my $t2 = sub {
		my $named = shift;
		my (@iv1) = @{shift()};
		my (@iv2) = @{shift()};
		my (@op1) = @{shift()};
		my (@op2) = @{shift()};
		my (@op3) = @{shift()};
		my $savecode = $_[0][0];
		my (@OPtext) = split(/^\s+([a-z]\w*):[\n\s]+/m, <<'END');
			e:
				my $j = exists $ar->[1];
			d:
				delete $ar->[1];
			f:
				my $j = $ar->[1];
			as:
				$ar->[1] = "$i.$n";
			ah:
				$ar->[1] = { $k => "$i.$n" };
			ao:
				$ar->[1] = "-$i.$n-" x ($ocut / length("-$i.$n-") + 1);
			pop:
				pop(@$ar);
			shi:
				shift(@$ar);
			phs:
				push(@$ar, "$i.$n");
			pho:
				push(@$ar, { $k => "$i.$n" });
			phO:
				push(@$ar, "-$i.$n-" x ($ocut / length("-$i.$n-") + 1));
			uns:
				unshift(@$ar, "$i.$n");
			uso:
				unshift(@$ar, { $k => "$i.$n" });
			usO:
				unshift(@$ar, "-$i.$n-" x ($ocut / length("-$i.$n-") + 1));
			cl1:
				$#$ar = -1;
			cl2:
				@$ar = ();
			s00:
				no warnings;
				splice(@$ar, 1, 0);
			s0s:
				no warnings;
				splice(@$ar, 1, 0, "$i.$n");
			s0o:
				no warnings;
				splice(@$ar, 1, 0, { $k => "$i.$n" });
			s0O:
				no warnings;
				splice(@$ar, 1, 0, "-$i.$n-" x ($ocut / length("-$i.$n-") + 1));
			s2s:
				no warnings;
				splice(@$ar, 1, 2, "$i.$n");
			s2o:
				no warnings;
				splice(@$ar, 1, 2, { $k => "$i.$n" });
			s2O:
				no warnings;
				splice(@$ar, 1, 2, "-$i.$n-" x ($ocut / length("-$i.$n-") + 1));
END
		#print join("\n---------------\n", @OPtext);
		#print "\n";
		shift(@OPtext) unless $OPtext[0] =~ /\w/;
		my (%OPtext) = @OPtext;
		my %OP;
		for my $op (keys %OPtext) {
			eval " \$OP{\$op} = sub { my (\$ar, \$i, \$n, \$k, \$op) = \@_; $OPtext{$op} }; ";
			die "eval <<$OPtext{$op}>>: $@" if $@;
		}
			
		my $root = $named->{root};
		my $i;
		my $n = 0;
		for my $jj (0..2) {
			if ($savecode & (2**$n)) {
				$r1->save;
			}
			$n++;

			for my $op1 (@op1) {
				for my $iv1 (@iv1) {
					for my $op2 (@op2) {
						for my $iv2 (@iv2) {
							for my $op3 (@op3) {
								my $k = "$iv1.$iv2.$op1.$op2.$op3";
								my $op = ($op1, $op2, $op3)[$jj];
								$i++;
								die unless exists $OP{$op};
								my $o = $OP{$op};
								print "# $OPtext{$op}\n" if $debug && $Npossible == 1 && $Nvert;
								&$o($root->{$k}, $i, $n, $k, $op);
							}
						}
					}
				}
			}
		}
	};

	my (@iv) = qw(s o O u e);
	my (@op) = qw(e d f as ah ao pop shi phs pho phO uns uso usO cl1 cl2 s00 s0s s0o s0O s2s s2o s2O);
	for my $iv1 (@iv) {
		for my $iv2 (@iv) {
			for my $op (@op) {
				for my $save (0) {
					runtests($t1, $t2, [qw(virt0)], [0,31], [$iv1], [$iv2], [@op], [@op], [$op], [$save]);
				}
			}
		}
	}
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;

