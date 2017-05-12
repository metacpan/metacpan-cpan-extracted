=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::XSAccessor accelerates particular methods with XS.

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
use Test::Moose;

{
	package Local::Class;
	use Moose;
	BEGIN { eval "use MooseX::XSAccessor" };
	has thingy => (is => "rw", isa => "Any", predicate => "has_thingy");
	has number => (is => "rw", isa => "Num", predicate => "has_number");
	has numero => (is => "ro", isa => "Num", predicate => "has_numero");
	has semi   => (is => "ro", isa => "Str", predicate => "has_semi", writer => "set_semi");
	has trig   => (reader => "get_trig", writer => "set_trig", trigger => sub { 1 });
}

my @expected_xsub = qw/ thingy numero semi get_trig /;
my @expected_pp   = qw/ new number set_semi set_trig /;
my @maybe_xsub    = qw/ has_thingy has_number has_numero has_semi /;

push @{
	(Class::XSAccessor->VERSION > 1.16) ? \@expected_xsub : \@expected_pp
}, @maybe_xsub;

with_immutable {
	my $im = "Local::Class"->meta->is_immutable ? "immutable" : "mutable";
	ok(
		MooseX::XSAccessor::is_xs("Local::Class"->can($_)),
		"$_ is an XSUB ($im class)",
	) for @expected_xsub;
	ok(
		!MooseX::XSAccessor::is_xs("Local::Class"->can($_)),
		"$_ is pure Perl ($im class)",
	) for @expected_pp;
} qw(Local::Class);

done_testing;
