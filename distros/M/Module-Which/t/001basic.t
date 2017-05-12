
use Test::More tests => 2;
BEGIN { use_ok('Module::Which') };

my @pm = qw(A X A::AA A::AB);

use lib qw(t/tlib);
my $info = which(@pm, { return => 'ARRAY' });

#use YAML;
#diag(YAML::Dump $info);

is_deeply($info,  [ 
    { version => 1, pm => 'A', path => 't/tlib/A.pm', base => 't/tlib' },
    { version => 1, pm => 'X', path => 't/tlib/X.pm', base => 't/tlib' },
    { version => 1, pm => 'A::AA', path => 't/tlib/A/AA.pm', base => 't/tlib' },
    { version => 1, pm => 'A::AB', path => 't/tlib/A/AB.pm', base => 't/tlib' },
], "simple test is ok");