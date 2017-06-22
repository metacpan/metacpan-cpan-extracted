use strict;
use warnings;

use Test::More;

plan tests => 1;

use PPR;

my $source = do { local (@ARGV, $/) = $INC{'PPR.pm'}; readline; };

ok $source =~ m{ \A (?&PerlDocument) \Z  $PPR::GRAMMAR }xms => 'Matched own document';

done_testing();

