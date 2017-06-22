use strict;
use warnings;

use Test::More;

plan tests => 4;

use PPR;

my $JAPH = <<'END_SOURCE';
not exp log srand xor s qq qx xor
s x x length uc ord and print chr
ord for qw q join use sub tied qx
xor eval xor print qq q q xor int
eval lc q m cos and print chr ord
for qw y abs ne open tied hex exp
ref y m xor scalar srand print qq
q q xor int eval lc qq y sqrt cos
and print chr ord for qw x printf
each return local x y or print qq
s s and eval q s undef or oct xor
time xor ref print chr int ord lc
foreach qw y hex alarm chdir kill
exec return y s gt sin sort split
END_SOURCE


ok $JAPH =~ m{ \A (?&PerlOWS) (?&PerlDocument) (?&PerlOWS) \Z  $PPR::GRAMMAR }xms 
    => "matched blokhead's wonderful JAPH!";

my $output = do {
    no warnings;
    local *STDOUT;
    my $output;
    ok open(\*STDOUT, '>', \$output)    => 'Redirected output';
    ok defined(eval $JAPH)              => 'Executed JAPH';
    $output;
};

is $output, 'just another perl hacker'   => 'JAPH is correct';

done_testing();

