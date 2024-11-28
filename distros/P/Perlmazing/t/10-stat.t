use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 15;
use Perlmazing;

my $stat_1 = stat $0;
my $stat_2 = CORE::stat $0;
my @stat = CORE::stat $0;
my @keys = Perlmazing::Object::Stat->_keys;

is @stat == @keys, 1, 'Expected number of values in stat are the same as in Perlmazing stat';

is $stat_1 == $stat_2, 1, 'Stringified version is valid';

for (my $i = 0; $i < @stat; $i++) {
    is $stat[$i], $stat_1->{$keys[$i]}, $keys[$i].' has a correct value';
}
