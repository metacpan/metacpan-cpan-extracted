use strict;
use warnings;

use Test::More;
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;

can_ok('SQL::Abstract', qw/insert_multi update_multi/);
my $sql = SQL::Abstract->new;
isa_ok($sql, 'SQL::Abstract');

done_testing;

