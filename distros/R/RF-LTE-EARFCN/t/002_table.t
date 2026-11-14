use strict;
use warnings;

use Test::More tests => 18;
BEGIN { use_ok('RF::LTE::EARFCN') };

my $rf = RF::LTE::EARFCN->new;
isa_ok($rf, 'RF::LTE::EARFCN');

my $table = $RF::LTE::EARFCN::BAND_TABLE;
isa_ok($table, 'ARRAY');
is(scalar(@$table), 67, 'size of @BAND_TABLE');

is($table->[0]->[0],      1);
is($table->[0]->[1],   2110);
is($table->[0]->[2],      0);
is($table->[0]->[3],    599);
is($table->[0]->[4],   1920);
is($table->[0]->[5],  18000);
is($table->[0]->[6],  18599);

is($table->[-1]->[0],    103);
is($table->[-1]->[1],    757);
is($table->[-1]->[2],  70646);
is($table->[-1]->[3],  70655);
is($table->[-1]->[4],    787);
is($table->[-1]->[5], 134282);
is($table->[-1]->[6], 134291);
