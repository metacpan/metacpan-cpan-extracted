use Test::More;

use Object::Iterate;
use Object::Iterate::Tester;

my $o = Object::Iterate::Tester->new();
isa_ok( $o, 'Object::Iterate::Tester' );
can_ok( $o, $Object::Iterate::More );
can_ok( $o, $Object::Iterate::Next );

foreach ( qw(a b c d e) ) {
	is( $o->$Object::Iterate::Next, $_, 'Fetched right element' );
	ok( $o->$Object::Iterate::More, 'Object has more elements' );
	}

is( $o->$Object::Iterate::Next, 'f', 'Fetched right element' );
my $more = not $o->$Object::Iterate::More;
ok( $more, 'Object has no more elements' );

done_testing();
