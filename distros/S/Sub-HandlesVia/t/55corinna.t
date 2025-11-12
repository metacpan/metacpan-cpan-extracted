use Test::Requires '5.038';
use Test::More;
use experimental 'class';

class Kitchen {
	field $foods :param = [];
	method foods () { return $foods }
	method _set_foods ($new) { $foods = $new }
	use Sub::HandlesVia::Declare [ 'foods', '_set_foods', sub { [] } ],
		Array => (
			all_foods => 'all',
			add_food  => 'push',
			eat_all   => 'reset',
		);
}

my $kitchen = Kitchen->new;
$kitchen->add_food( 'apples' );
$kitchen->add_food( 'carrots' );
is_deeply( [ $kitchen->all_foods ], [ qw/ apples carrots / ] );

$kitchen->eat_all;
is_deeply( $kitchen->foods, [] );

done_testing;
