#	perl script -- run with perl <scriptname>

delete $ENV{PERL5OPT};
$ENV{PARENT}="{name=>\"P.t\", pid=>$$}";
#use lib ($bin . "/../blib", $bin . "/../blib/lib");
use Config;

my $myprog = ($0=~/^(.*)\.[^\.]+$/)[0];
$myprog = $0 unless $myprog;

#probably not needed? $ENV{PERL5LIB}=join ':', @INC;
# test w/o to see if it lets Windows work.


system $^X . " $myprog.Pt", @ARGV;

# vim: syntax=perl

