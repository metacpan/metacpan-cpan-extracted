=pod

=encoding utf-8

=head1 PURPOSE

Demonstration that Role::Hooks works with L<Package::Variant>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

# This just skips the test if the necessary packages are unavailable.
#
{ package Local::Dummy1; use Test::Requires 'Moo';  };
{ package Local::Dummy2; use Test::Requires 'Moo::Role'; };
{ package Local::Dummy2; use Test::Requires 'Package::Variant'; };

my @GOT;

BEGIN {
	package Local::VariableRole;

	use Package::Variant
		importing => [ 'Moo::Role', 'Role::Hooks' ],
		subs => [ qw(has around before after with) ];

	sub make_variant {
		# Note that the generated package name for the role is passed as the
		# first argument (after $self) to make_variant.
		#
		my ( $self, $role_name, %arguments ) = @_;

		my $name = $arguments{name};
		has $name => ( is => 'ro' );

		# That generated package name for the role must be passed to
		# before_apply.
		#
		'Role::Hooks'->before_apply( $role_name, sub {
			my ( $role, $applied_to ) = @_;
			push @GOT, "About to add attribute $name to $applied_to";
		} );

		# The same for after_apply.
		#
		'Role::Hooks'->after_apply( $role_name, sub {
			my ( $role, $applied_to ) = @_;
			push @GOT, "Applied attribute $name to $applied_to";
		} );
	}

	$INC{'Local/VariableRole.pm'} = __FILE__;
};

BEGIN {
	package Local::MyClass;

	use Moo;
	use Local::VariableRole;

	with
		VariableRole( name => 'foo' ),
		VariableRole( name => 'bar' );
};

is_deeply(
	[ sort { $a cmp $b } @GOT ],
	[ sort { $a cmp $b } (
		'About to add attribute foo to Local::MyClass',
		'About to add attribute bar to Local::MyClass',
		'Applied attribute foo to Local::MyClass',
		'Applied attribute bar to Local::MyClass',
	) ],
	'Expected result',
) or diag explain( \@GOT );

done_testing;
