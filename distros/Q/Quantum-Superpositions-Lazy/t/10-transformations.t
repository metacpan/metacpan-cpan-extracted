use v5.24;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy qw(superpos with_sources);

##############################################################################
# A check of transformations - whether it morphs all the states.
##############################################################################

my $case = superpos(2, 3);
my $morphed = $case->transform(sub { shift() > 2 ? "yes" : "no" });

use Data::Dumper;
note Dumper(with_sources { $morphed->states });

ok $morphed eq "yes", "morph ok";
ok $morphed eq "no", "morph ok";

done_testing;
