use Test::More;
use Rope;



{
	package Locked;

	use Rope;
	use Rope::Autoload;
	use Rope::Variant;
	use Types::Standard qw/Str/;

	variant string => (
		given => Str,
		when => [
			'one' => { 
			    run => sub { return "$_[1] - cold, cold, cold inside" },
			},
			'two' => {
			    run => sub { return "$_[1] - don't look at me that way"; },
			},
			'three' => {
			    run => sub { return "$_[1] - how hard will i fall if I live a double life"; },
			},
		],
	);

	variant string => (
		when => [
			four => {
				run => sub {
					return "$_[1] - we can extend";
				}
			}
		]
	);


	1;
}

my $k = Locked->new(string => 'one');

is($k->string, 'one - cold, cold, cold inside');

$k->string = 'two';

is($k->string, "two - don't look at me that way");

$k->string = 'three';

is($k->string, 'three - how hard will i fall if I live a double life');

$k->string = 'four';

is($k->string, 'four - we can extend');

ok(1);

done_testing();
