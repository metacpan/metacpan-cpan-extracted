=pod

=head1 PURPOSE

Test that all Moose's built-in type constraints are correctly parsed.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

require Moo;

my @types_to_check = qw(
	Any
	Item
	Bool
	Maybe
	Maybe[Int]
	Undef
	Defined
	Value
	Str
	Num
	Int
	ClassName
	RoleName
	Ref
	ScalarRef
	ScalarRef[Int]
	ArrayRef
	ArrayRef[Int]
	HashRef
	HashRef[Int]
	CodeRef
	RegexpRef
	GlobRef
	FileHandle
	Object
	Int|ArrayRef[Int]
	ArrayRef[Int|HashRef[Int]]
	ArrayRef[HashRef[Int]|Int]
	ArrayRef[HashRef[Int]]|Int
);

my @class_types_to_check = qw(
	Local::Test1
	Local::Test::Two
	LocalTest3
);

my $count = 0;
sub constraint_for
{
	my $type = shift;
	
	# Note that this will cause Local::Test1 to exist.
	# We later use that in a @class_types_to_check test.
	#
	my $class = "Local::Test" . ++$count;
	
	eval qq{
		package $class;
		use Moo;
		use MooX::late;
		has attr => (is => "ro", isa => "$type");
		1;
	} or diag($@);
	
	"Moo"->_constructor_maker_for($class)->all_attribute_specs->{attr}{isa};
}

for my $type (@types_to_check)
{
	my $got = constraint_for($type);
	isa_ok($got, "Type::Tiny", "constraint_for('$type')");
	is("$got", "$type", "Type constraint returned for '$type' looks right.");
}

for my $type (@class_types_to_check)
{
	my $got = constraint_for($type);
	isa_ok($got, "Type::Tiny::Class", "constraint_for('$type')");
	is($got && $got->class, $type, "Type constraint returned for '$type' looks right.");
}

{
	my $type = 'ArrayRef[Local::Test1]';
	my $got  = constraint_for($type);
	isa_ok($got, "Type::Tiny", "constraint_for('$type')");
	is(
		$got && $got->type_parameter && $got->type_parameter->class,
		"Local::Test1",
		"Type constraint returned for '$type' looks right"
	);
}

done_testing;
