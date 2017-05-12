use strict;
use warnings;

use lib 't/lib';

use UseCase::Two;

use Test::More;

my $bou = UseCase::Two->new;

like $bou->page => qr/<head>\s+<title>/;

done_testing;
