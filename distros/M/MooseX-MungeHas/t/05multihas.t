=pod

=encoding utf-8

=head1 PURPOSE

Test that it is possible to export multiple C<has> mungers.

=head1 DEPENDENCIES

Test requires Moose 2.0000 or is skipped.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Requires { "Moose" => "2.0000" };
use Test::More;

{
	package Local::Class1;
	use Moose;
	use MooseX::MungeHas {
		has_ro  => ['is_ro'],
		has_rw  => ['is_rw'],
	};
	has_ro "attr1";
	has_ro "attr2", sub { 666 };
	has_rw "attr3";
	has_rw "attr4", sub { 999 };
}

is(
	Local::Class1->meta->get_attribute("attr$_")->{is},
	"ro",
	qq[Local::Class1->meta->get_attribute("attr$_")->{is} eq "ro"],
) for 1, 2;

is(
	Local::Class1->meta->get_attribute("attr$_")->{is},
	"rw",
	qq[Local::Class1->meta->get_attribute("attr$_")->{is} eq "rw"],
) for 3, 4;

is(
	Local::Class1->new->attr2,
	666,
	'$o->attr2 builder',
);

is(
	Local::Class1->new->attr4,
	999,
	'$o->attr4 builder',
);

done_testing;
