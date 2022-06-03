use Test::More;

{
	package One;
	use Moo;
	use Data::Dumper;
	use Factory::Sub qw/Str HashRef/;
	our %FIELDS;

	use MooX::Keyword extends => '+Field', param => {
		builder => sub {
			use Data::Dumper;
			shift->has(shift, is => 'rw', @_);
		}
	};

	param "one";

	field thing => ( is => 'rw' );

	field built => ( 
		builder => sub {
			return 'builder';
		}
	);

	1;
}

my $n = One->new({thing => 'one', build => 'nope', one => 'okay' });
is($n->one, 'okay');
is($n->thing, undef);
is($n->thing('two'), 'two');
is($n->thing, 'two');
is($n->built, 'builder');


done_testing();

