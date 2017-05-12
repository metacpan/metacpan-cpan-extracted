=pod

=encoding utf-8

=head1 PURPOSE

Test case based on
L<http://stackoverflow.com/a/22637443/1990570>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
use Test::Moose;

BEGIN {
	package My::Legacy::MyMooseObj;

	use Moose;
	use MooseX::FunkyAttributes;
	use namespace::autoclean;

	has _fields => (
		isa         => 'HashRef',
		is          => 'rw',
		default     => sub { {} },
		lazy        => 1,  # you want this, for the rest to work
	);

	sub funky_has {
		my ($attr, %opts) = @_;
		has $attr => (
			is          => 'ro',
			traits      => [ FunkyAttribute ],
			custom_get  => sub { $_->_fields->{$attr} },
			custom_set  => sub { $_->_fields->{$attr} = $_[-1] },
			custom_has  => sub { exists($_->_fields->{$attr}) },
			%opts,
		);
	}

	funky_has attr_a => (isa => 'Int');
	funky_has attr_b => (isa => 'Str', is => 'rw');
};

with_immutable
{
	my $obj = My::Legacy::MyMooseObj->new( attr_a => 42 );
	$obj->attr_b(666);
	is_deeply($obj->_fields, { attr_a => 42, attr_b => 666 });
} qw( My::Legacy::MyMooseObj );

done_testing();
