=pod

=encoding utf-8

=head1 PURPOSE

Check the C<InsideOut> trait works using mostly the same C<Circle>
class as in C<< t/02funky.t >>, but the C<radius> attribute stored
inside out.

Checks the hashref's guts to make sure no attributes are inadvertantly
stored there.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN {
	package Local::Circle;
	no thanks;
	use Moose;
	use MooseX::FunkyAttributes;
	use constant PI => 3.14159;
	has radius => (
		traits     => [ InsideOutAttribute ],
		is         => 'rw',
		isa        => 'Num',
		predicate  => 'has_radius',
		clearer    => 'clear_radius',
	);
	has diameter => (
		traits     => [ FunkyAttribute ],
		is         => 'rw',
		isa        => 'Num',
		custom_set => sub { $_[1]->radius($_[2] / 2) },
		custom_get => sub { 2 * $_[1]->radius },
		custom_has => sub { 1 },
	);
	has circumference => (
		traits     => [ FunkyAttribute ],
		is         => 'rw',
		isa        => 'Num',
		custom_set => sub { $_[1]->diameter($_[2] / PI) },
		custom_get => sub { PI * $_[1]->diameter },
		custom_has => sub { 1 },
	);
	has area => (
		traits     => [ FunkyAttribute ],
		is         => 'rw',
		isa        => 'Num',
		custom_set => sub { $_[1]->radius( sqrt($_[2]/PI) ) },
		custom_get => sub { PI * ( $_[1]->radius ** 2 ) },
		custom_has => sub { 1 },
	);
}

#######################################################################

use Test::More tests => 48;
use Test::Fatal;
use Test::Moose;

with_immutable
{
	my $circle1 = new_ok 'Local::Circle' => [ radius => 10 ];
	
	is($circle1->radius,            10, '$circle1->radius');
	is($circle1->diameter,          20, '$circle1->diameter');
	is(int $circle1->circumference, 62, '$circle1->circumference');
	is(int $circle1->area,         314, '$circle1->area');
	
	$circle1->diameter(100); # bigger
	
	is($circle1->radius,             50, '$circle1->radius');
	is($circle1->diameter,          100, '$circle1->diameter');
	is(int $circle1->circumference, 314, '$circle1->circumference');
	is(int $circle1->area,         7853, '$circle1->area');
	
	my $circle2 = new_ok 'Local::Circle' => [ circumference => 100 ];
	
	is(int $circle2->radius,         15, '$circle2->radius');
	is(int $circle2->diameter,       31, '$circle2->diameter');
	is(int $circle2->circumference, 100, '$circle2->circumference');
	is(int $circle2->area,          795, '$circle2->area');
	
	foreach my $attr (qw( radius diameter circumference area ))
	{
		like(
			exception { $circle2->$attr("Foo") },
			qr{Validation failed for 'Num'},
			qq{Type constraint for $attr still enforced},
		);
	}
	
	my %guts = %$circle1;
	foreach my $attr (qw( radius diameter circumference area ))
	{
		ok(!exists $guts{$attr}, "key '$attr' not found in \$circle1 guts")
	}
	
	ok($circle1->has_radius, '$circle1->has_radius');
	
	$circle1->clear_radius;
	ok(!$circle1->has_radius, '$circle1->clear_radius');
	
} qw( Local::Circle );
