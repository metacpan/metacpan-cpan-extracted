use warnings;
use strict;

use Test::More tests => 5;
BEGIN { use_ok('Math::Calc') };

#########################

my $input = q{
a = 2*3
b = a+1 # a comment
# white lines

c = a-b
d = a-c
};
my $parser = Math::Calc->new();
$parser->input(\$input);
my %s = %{$parser->Run()};
is($s{a}, 6, "a=2*3 is 6");
is($s{b}, 7, "b=a+ 1 is 7");
is($s{c}, -1, "c=a-b is -1");
is($s{d}, 7, "d = a-c is 7");


