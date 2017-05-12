=head1 PURPOSE

Test C<on_inflation> hook from L<MooX::CaptainHook> when Moose is loaded
early.

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

BEGIN {
	eval { require Moose } or plan skip_all => 'need Moose';
};

my @inflated;

{
	package Foo;
	use Moo;
	use MooX::CaptainHook qw( on_inflation );
	on_inflation {
		push @inflated, sprintf("%s (%s)", $_->name, $_->isa('Moose::Meta::Role')?'Role':'Class');
	};
}

{
	package Boo;
	use Moo::Role;
	use MooX::CaptainHook qw( on_inflation );
	on_inflation {
		push @inflated, sprintf("%s (%s)", $_->name, $_->isa('Moose::Meta::Role')?'Role':'Class');
	};
}

Class::MOP::class_of('Foo')->name;
Class::MOP::class_of('Boo')->name;

is_deeply(
	[ sort @inflated ],
	[
		"Boo (Role)",
		"Foo (Class)",
	],
) or diag explain \@inflated;

done_testing;
