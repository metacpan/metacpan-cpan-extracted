use strict;
use warnings;

use lib 't/lib';

use UseCase::One;

use Test::More;

my $bou = UseCase::One->new; 

ok $bou->can( "usecase_1" ), 'template loaded';

my $output = $bou->usecase_1;

like $output => qr#^<html>\n\s{2}<head>#m, "nicely formatted";

done_testing;
