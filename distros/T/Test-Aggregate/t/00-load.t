#!perl 

use Test::More tests => 4;

use lib 't/lib';

BEGIN {
    my $v = $Test::More::VERSION;
    cmp_ok($v, '<', 1.3, 'Compatible Test::Builer')
        or BAIL_OUT(<< "__BAIL_OUT__");
This module only works with Test::More version < 1.3, but you have $v.
__BAIL_OUT__

    use_ok('Test::Aggregate')       or die;
    use_ok('Slow::Loading::Module') or die;
}

diag("Testing Test::Aggregate $Test::Aggregate::VERSION, Perl $], $^X");
diag("... with Test::Builder $Test::Builder::VERSION");

ok !exists $ENV{aggregated_current_script},
  'env variables should not hang around';
$ENV{aggregated_current_script} = $0;
