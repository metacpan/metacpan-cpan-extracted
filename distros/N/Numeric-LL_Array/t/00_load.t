# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Numeric-Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use Test::More tests => 1 ;

BEGIN { use_ok('Numeric::LL_Array') };

exit if eval "use Numeric::LL_Array; 1";

warn "# reporting Makefile header:\n# ==========================\n";
my ($base_d, $in) = (-f "t/sinl.t" ? '.' : '..', '');
open M, "< $base_d/Makefile" or die "Can't open $base_d/Makefile";
$in = <M> while defined $in and $in !~ /MakeMaker \s+ Parameters/xi;
$in = <M>;
$in = <M> while defined $in and $in !~ /\S/;
warn $in and $in = <M> while defined $in and $in =~ /^#/;
close M;
warn "# ==========================\n";
