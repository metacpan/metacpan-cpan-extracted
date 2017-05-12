# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
sub t { my $f=shift;$t++;my $str=($f)?"ok $t":"not ok $t";print $str,"\n";}
use System::Index;
$loaded = 1;
t 1;
t cpu_index()+1;
t hd_index()+1;
t mem_index()+1;
