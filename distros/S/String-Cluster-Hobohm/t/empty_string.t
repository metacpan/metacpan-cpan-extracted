use strict;
use warnings;
use Test::More;
use Test::Exception;

use String::Cluster::Hobohm;

my $c = String::Cluster::Hobohm->new();

my $g;

lives_ok { $g = $c->cluster( [ 'foo', 'foa', '', ] ) }
'lives with an empty string';

is_deeply $g, [ [ \'foo', \'foa' ], [ \'' ] ],
  'clustering works with empty strings';

done_testing();
