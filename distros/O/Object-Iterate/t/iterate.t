use Test::More;
use lib qw(t/lib);

use Object::Iterate qw(iterate);

my $class         = 'Object::Iterate';
my $function_name = 'iterate';
my $object_class  = 'Object::Iterate::Tester';

subtest 'load object class' => sub {
	use_ok $object_class;
	can_ok $object_class, 'new';
	isa_ok $object_class->new, $object_class;
	};

subtest 'list context' => sub {
	my $o = $object_class->new;
	isa_ok $o, $object_class;
	ok defined &{"$function_name"}, "$function_name is defined";

	my @expected = map { "$_$_" } qw( a b c d e f );

	my @got;
	iterate { push @got, "$_$_" } $o;
	is_deeply \@got, \@expected, "$function_name gives the right results";
	};

subtest 'empty set' => sub {
	my $empty_class = 'Local::Empty';
	use_ok $empty_class;
	can_ok $empty_class, 'new';
	my $o = $empty_class->new;
	isa_ok $o, $empty_class;

	my @got;
	iterate { push @got, "$_$_" } $o;
	is scalar @got, 0, 'the empty class returns no results';
	};

done_testing();
`	`
