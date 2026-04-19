use lib qw(t/lib);
use Test::More;

use Object::Iterate qw(igrep);

my $class         = 'Object::Iterate';
my $function_name = 'igrep';
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

	my @expected = qw( a e );
	my %Vowels = map { $_, 1 } @expected;

	my @O = igrep { exists $Vowels{$_} } $o;
	ok( eq_array( \@O, \@expected ), "$function_name gives the right results" );
	};

subtest 'scalar context' => sub {
	my $o = $object_class->new;
	isa_ok $o, $object_class;

	my @expected = qw( b c d f );
	my %NotVowels = map { $_, 1 } @expected;

	my $count = igrep { exists $NotVowels{$_} } $o;
	is $count, scalar @expected, 'there are the expected number of results';
	};

subtest 'empty set' => sub {
	my $empty_class = 'Local::Empty';
	use_ok $empty_class;
	can_ok $empty_class, 'new';
	my $o = $empty_class->new;
	isa_ok $o, $empty_class;

	my $count = igrep { 1 } $o;
	is $count, 0, 'the empty class returns no results';
	};

done_testing();
