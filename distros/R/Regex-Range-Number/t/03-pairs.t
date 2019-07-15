use Test::More;

use Regex::Range::Number;

my $generator = Regex::Range::Number->new();

my %helper = $generator->helpers();

my $range = $generator->number_range([[55, 56], [75, 89], [99, 100]]);
is($range, '55|56|7[5-9]|8[0-9]|99|100');

$range = $generator->number_range([[55, 56], [75, 89], [99, 100]], {capture => 1});
is($range, '(55|56|7[5-9]|8[0-9]|99|100)');

$range = $generator->number_range([[55, 56], [75, 89], [99, 100]], {capture => 1, individual => 1});
is($range, '((55|56)|(7[5-9]|8[0-9])|(99|100))');


$range = $generator->number_range([[55, 56], [75, 89], [92, 100]], {individual => 1});
is($range, '(55|56)|(7[5-9]|8[0-9])|(9[2-9]|100)');




done_testing();

1;
