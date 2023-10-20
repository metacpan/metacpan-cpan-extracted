use Test::More;

use lib 't/lib';

use Two;

my $two = Two->new;
is($two->one(), 50);

is($two->one(10), 10);
is($two->two(), 50);
is($two->three(), 100);

$two = Two->new(one => sub { return 999 }, four => 55);

is($two->one(), 999);

$two->one = sub { return 1000; };

is($two->one(), 1000); 

is($two->four, 55);

my @keys = keys %{$two};

is_deeply(\@keys, [qw/one two three four/]);

done_testing();
