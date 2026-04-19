use Test::More;
use lib qw(t/lib);

use Object::Iterate qw(imap);

my $class         = 'Object::Iterate';
my $function_name = 'imap';
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

	my @expected = qw( A B C D E F );

	my @O = imap { uc($_) } $o;
	ok( eq_array( \@O, \@expected ), "$function_name gives the right results" );
	};

subtest 'scalar context' => sub {
	my $o = $object_class->new;
	isa_ok $o, $object_class;

	my $count = imap { 1 } $o;
	is $count, 6, 'there are the expected number of results';
	};

subtest 'empty set' => sub {
	my $empty_class = 'Local::Empty';
	use_ok $empty_class;
	can_ok $empty_class, 'new';
	my $o = $empty_class->new;
	isa_ok $o, $empty_class;

	my $count = imap { 1 } $o;
	is $count, 0, 'the empty class returns no results';
	};

done_testing();
