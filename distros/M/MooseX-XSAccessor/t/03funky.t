=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::XSAccessor works OK with MooseX::FunkyAttributes.

=head1 DEPENDENCIES

MooseX::FunkyAttributes 0.002; test skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Requires { "MooseX::FunkyAttributes" => "0.002" };

{
	package Local::Storage;
	use Moose;
	use MooseX::XSAccessor;
	has slot => (is => "rw");
}

{
	package Local::Class;
	use Moose;
	use MooseX::XSAccessor;
	use MooseX::FunkyAttributes;
	has storage => (
		is                 => "ro",
		default            => sub { "Local::Storage"->new },
	);
	has delegated => (
		is                 => "rw",
		traits             => [ DelegatedAttribute ],
		delegated_to       => "storage",
		delegated_accessor => "slot",
	);
}

my $o = "Local::Class"->new;
$o->delegated(42);

is_deeply(
	$o,
	bless(
		{
			storage => bless(
				{
					slot => 42,
				},
				"Local::Storage",
			),
		},
		"Local::Class",
	),
);

done_testing;
