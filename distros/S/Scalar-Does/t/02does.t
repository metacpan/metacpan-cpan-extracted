=head1 PURPOSE

Test various scalars and roles to check we get expected results.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Scalar::Does;

{
	package Local::Does::Array;
	use overload '@{}' => 'array';
	sub new   { bless +{ array=>[] }, pop };
	sub array { return shift->{array} };
	sub DOES  { return 1 if $_[1] eq 'Monkey'; shift->SUPER::DOES(@_) }
}

{
	package Local::Does::Not;
	sub new   { bless +{ array=>[] }, pop };
	sub can   { return if $_[1] eq 'DOES'; shift->SUPER::can(@_) }
	sub DOES  { +die }
}

{
	package Cruddy::Role;
	sub new   { bless +{ array=>[] }, pop };
}

{
	package Permissive::Role;
	sub new   { bless +{ array=>[] }, pop };
	sub check { 1 }
}

my %tests = (
	undef => [
		undef,
		does   => [qw( 0+ "" bool )],
		doesnt => [qw( SCALAR @{} Regexp CODE &{} Foo::Bar UNIVERSAL )],
	],
	ARRAY => [
		[],
		does   => [qw( ARRAY @{} )],
		doesnt => [qw( HASH %{} )],
	],
	HASH => [
		+{},
		does   => [qw( HASH %{} )],
		doesnt => [qw( ARRAY @{} )],
	],
	SCALAR => [
		\"Hello World",
		does   => [qw( SCALAR ${} )],
		doesnt => [qw( ARRAY HASH @{} %{} CODE Regexp Foo::Bar UNIVERSAL )],
	],
	CODE => [
		sub { 1 },
		does   => [qw( CODE &{} )],
		doesnt => [qw( SCALAR @{} UNIVERSAL )],
	],
	Blessed_CODE => [
		bless(sub { 1 } => 'Foo::Bar'),
		does   => [qw( CODE &{} Foo::Bar UNIVERSAL )],
		doesnt => [qw( SCALAR @{} Regexp )],
	],
	Overloaded_Object => [
		Local::Does::Array->new,
		does   => [qw( ARRAY @{} HASH %{} Local::Does::Array UNIVERSAL Monkey )],
		doesnt => [qw( CODE bool "" Gorilla )],
	],
	Overloaded_Class => [
		'Local::Does::Array',
		does   => [qw( bool "" Local::Does::Array UNIVERSAL Monkey )],
		doesnt => [qw( CODE Gorilla HASH %{} ARRAY @{} )],
	],
	STDOUT => [
		\*STDOUT,
		does   => [qw( IO <> GLOB *{} )],
		doesnt => [qw( SCALAR @{} Regexp CODE &{} Foo::Bar UNIVERSAL )],
	],
	Lvalue => [
		\(substr($INC[0], 0, 1)),
		does   => [qw( LVALUE )],
		doesnt => [qw( SCALAR @{} Regexp CODE &{} Foo::Bar UNIVERSAL IO GLOB )],
	],
	Object_without_DOES_method => [
		Local::Does::Not->new,
		does   => [qw( HASH )],
		doesnt => [qw( Local::Does::Not )],
	],
	Class_without_DOES_method => [
		'Local::Does::Not',
		does   => [qw( )],
		doesnt => [qw( Local::Does::Not HASH )],
	],
);



my @uncheck = (
	Cruddy::Role->new,
	[],
	'FlibbleSocks',
);
my @check = (
	Permissive::Role->new,
);

foreach my $name (sort keys %tests)
{
	my ($value, %cases) = @{ $tests{$name} };
	
	foreach my $tc (@{ $cases{does} }) {
		ok(does($value, $tc), "$name does $tc");
	}

	foreach my $tc (@{ $cases{doesnt} }) {
		ok(!does($value, $tc), "$name doesn't $tc");
	}
	
	ok( does($value, $_), "$name does $_") for @check;
	ok(!does($value, $_), "$name doesn't do uncheckable role $_") for @uncheck;
}

done_testing();
