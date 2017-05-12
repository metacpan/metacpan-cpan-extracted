=head1 PURPOSE

Example showing the use of L<MooseX::FunkyAttributes> and
L<MooseX::CustomInitArgs> together.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use v5.14;

package Circle {

	use Moose;
	use MooseX::FunkyAttributes;
	use MooseX::CustomInitArgs;
	use Math::Trig 'pi';
	use namespace::autoclean;

	sub _number_delegation {
		my $attr = shift;
		handles => +{ map { ;"${attr}_${_}" => "$_" } qw(add sub mul div) };
	}

	has radius => (
		traits    => [ 'Number' ],
		is        => 'rw',
		isa       => 'Num',
		required  => 1,
		init_args => [
			diameter      => sub { $_ / 2 },
			circumference => sub { $_ / (2 * pi) },
			area          => sub { sqrt($_ / pi) },
		],
		_number_delegation('radius'),
	);

	has diameter => (
		traits => [ FunkyAttribute, 'Number' ],
		is     => 'rw',
		isa    => 'Num',
		custom_get => sub { 2 * $_->radius },
		custom_set => sub { $_->radius( $_[-1] / 2 ) },
		custom_has => sub { 1 },
		_number_delegation('diameter'),
	);

	has area => (
		traits => [ FunkyAttribute, 'Number' ],
		is     => 'rw',
		isa    => 'Num',
		custom_get => sub { pi * ($_->radius ** 2) },
		custom_set => sub { $_->radius(sqrt($_[-1]/pi)) },
		custom_has => sub { 1 },
		_number_delegation('area'),
	);

	has circumference => (
		traits => [ FunkyAttribute, 'Number' ],
		is     => 'rw',
		isa    => 'Num',
		custom_get => sub { pi * $_->diameter },
		custom_set => sub { $_->diameter( $_[-1] / pi ) },
		custom_has => sub { 1 },
		_number_delegation('circumference'),
	);

	sub dump {
		my $self = shift;
		sprintf(
			"%s[ r=%.03f d=%.03f c=%.03f A=%.03f ]",
			ref($self),
			$self->radius,
			$self->diameter,
			$self->circumference,
			$self->area,
		);
	}

	__PACKAGE__->meta->make_immutable;
}

say "Making a circle with radius=1";
my $ring = Circle->new(radius => 1);
say $ring->dump;
say "--";

say "Setting the circle's area to 4.5";
$ring->area(4.5);
say $ring->dump;
say "--";

say "Double circle's circumference";
$ring->circumference_mul(2);
say $ring->dump;
say "--";

say "Incremement the circle's diameter";
$ring->diameter_add(1);
say $ring->dump;
say "--";

say "Halve the circle's area";
$ring->area_div(2);
say $ring->dump;
say "--";

say "Making a new circle with area=1";
my $ring2 = Circle->new(area => 1);
say $ring2->dump;
say "--";
