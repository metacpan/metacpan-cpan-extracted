use Test::More;

use Regex::Range::Number qw/all/;

is_deeply($helper{nines}(100, 1), 109);

is_deeply($helper{ranges}(100, 1999), [ 109, 199, 999, 1999 ]);

is_deeply(
	$helper{split}(100, 1999, { min => 100, max => 1999, a => 100, b => 1999 }), [
   {
     'digits' => [
       1
     ],
     'pattern' => '10[0-9]',
     'string' => '10[0-9]'
   },
   {
     'digits' => [
       1
     ],
     'pattern' => '1[1-9][0-9]',
     'string' => '1[1-9][0-9]'
   },
   {
     'digits' => [
       2
     ],
     'pattern' => '[2-9][0-9]',
     'string' => '[2-9][0-9]{2}'
   },
   {
     'digits' => [
       3
     ],
     'pattern' => '1[0-9]',
     'string' => '1[0-9]{3}'
   }
]);

my $range = number_range(55, 56);
is($range, '55|56');

is('55' =~ $range, 1);


$range = number_range(55, 56, { capture => 1 });
is($range, '(55|56)');

$range = number_range(100, 1999);
is($range, '10[0-9]|1[1-9][0-9]|[2-9][0-9]{2}|1[0-9]{3}');
is(655 =~ $range, 1);

$range = number_range(100, 1999, { capture => 1 });
is($range, '(10[0-9]|1[1-9][0-9]|[2-9][0-9]{2}|1[0-9]{3})');

done_testing();

1;
