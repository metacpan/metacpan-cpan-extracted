use Test::More;
use lib 't/lib';
use Basic;

my $b = Basic->new;

is($b->str, 'abc');
is($b->one, 1); 
is($b->two, 2);

done_testing();
