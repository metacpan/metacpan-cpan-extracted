=pod

=encoding utf-8

=head1 PURPOSE

Tests kept from the original version of L<MooseX::Meta::Attribute::Lvalue>
to ensure backwards compatibility.

=head1 AUTHOR

Christopher Brown, C<< <cbrown at opendatagroup.com> >>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by Christopher Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

{
	package App;
	use Moose;
	with 'MooseX::Meta::Attribute::Lvalue';
	
	has 'name' => (
		traits  => [ 'Lvalue' ],
		is      => 'rw',
		isa     => 'Str',
	);
	
	has 'count' => (
		traits  => [ 'Lvalue' ],
		is      => 'rw',
		isa     => 'Int',
		default => 0,
	);
	
	has 'sign' => (
		is      => 'rw',
		isa     => 'Str',
	);
}

my $app = App->new( name => 'frank', sign => 'pisces' );

isa_ok( $app, "App" );

# DOES ROLES
ok( $app->meta->get_attribute( 'name' )->does( 'Lvalue' ), "Does Lvalue" );
ok( $app->meta->get_attribute( 'count' )->does( 'Lvalue' ), "Attribute 'count' does role 'Lvalue'" );
ok( $app->meta->get_attribute( 'sign' )->does( 'Lvalue' ) == 0, "Doesn't  Lvalue" );

eval { $app->sign = "aries" };   # lvalue is 0, does not get changed
ok( $app->sign eq "pisces", "Normal rw attribute" );

$app->name = "Ralph" ;
ok( $app->name eq "Ralph", "Lvalue attribute"  );

done_testing;
