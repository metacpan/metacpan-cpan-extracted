use strict;
use warnings;

use Test::More;
use Query::Param;

########################################################################
subtest 'Vars() flattens multiple values to last value' => sub {
########################################################################
  my $q = Query::Param->new('foo=1&foo=2&bar=3&empty=');

  my $vars = $q->Vars;

  is( ref $vars, 'HASH', 'Vars() returns a hashref' );

  is_deeply(
    $vars,
    { foo   => '2',
      bar   => '3',
      empty => q{},
    },
    'Vars() returns scalar values, last value wins for duplicates'
  );
};

########################################################################
subtest 'Vars() and params() diverge for multivalued keys' => sub {
########################################################################
  my $q = Query::Param->new('x=1&x=2');

  my $vars   = $q->Vars;
  my $params = $q->params;

  is( $vars->{x}, '2', 'Vars returns last value' );
  is_deeply( $params->{x}, [ '1', '2' ], 'params preserves all values as arrayref' );
};

done_testing();

1;

