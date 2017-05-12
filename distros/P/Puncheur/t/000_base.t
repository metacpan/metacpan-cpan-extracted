use strict;
use warnings;
use utf8;
use Test::More;

use Puncheur;
pass 'use Puncheur ok';

my $app = Puncheur->new;
ok $app;
isa_ok $app, 'Puncheur';

done_testing;
