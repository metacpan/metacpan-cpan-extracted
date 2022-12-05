=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::XSAccessor accelerates role attributes.

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
use Test::Moose;

{
	package Local::Role;
	use Moose::Role;
	BEGIN { eval "use MooseX::XSAccessor" };
	has my_str => (is => "ro", isa => "Str");
}

{
	package Local::Class;
	use Moose;
	BEGIN { eval "use MooseX::XSAccessor" };
	with 'Local::Role';
	has my_num => (is => "ro", isa => "Int");
}

my @expected_xsub = qw( my_str my_num );

with_immutable {
	my $im = "Local::Class"->meta->is_immutable ? "immutable" : "mutable";

	ok(
		MooseX::XSAccessor::is_xs("Local::Class"->can($_)),
		"$_ is an XSUB ($im class)",
	) for @expected_xsub;
} qw(Local::Class);

done_testing;
