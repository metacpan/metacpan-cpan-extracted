use Test::More;
{
	package One;
	use Moo;
	use MooX::Keyword extends => '+Factory';
	use Types::Standard qw/Str HashRef/;
	
	factory thing => Str, Str, sub {
		return 11;
	};

	factory thing => Str, HashRef, sub {
		return 22;
	};

	1;
}

use Data::Dumper;
my $n = One->new;

is($n->thing('one', 'two'), 11);
is($n->thing('one', { a => 'b' }), 22);
is($n->thing, 22);

done_testing();
