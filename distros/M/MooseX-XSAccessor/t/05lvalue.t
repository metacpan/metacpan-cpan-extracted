=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::XSAccessor works OK with L<MooseX::LvalueAttribute>.

=head1 DEPENDENCIES

MooseX::Attribute::Chained; test skipped otherwise.

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
use Test::Requires { "MooseX::LvalueAttribute" => "0.980" };

{
	package Local::Class;
	use Moose;
	use MooseX::XSAccessor;
	use MooseX::LvalueAttribute;
	
	local $MooseX::XSAccessor::LVALUE = 1;
	has foo => (traits => ["Lvalue"], is => "rw");
	has bar => (                      is => "rw");
	
	sub quux { 42 };
}

my $o = "Local::Class"->new(foo => 1, bar => 2);

ok($o->meta->get_attribute('foo')->does('MooseX::XSAccessor::Trait::Attribute'));
ok($o->meta->get_attribute('foo')->does('MooseX::LvalueAttribute::Trait::Attribute'));

ok($o->meta->get_attribute('bar')->does('MooseX::XSAccessor::Trait::Attribute'));
ok(not $o->meta->get_attribute('bar')->does('MooseX::LvalueAttribute::Trait::Attribute'));

is($o->foo, 1);
is($o->bar, 2);

$o->foo++;
$o->bar($o->bar + 1);

is($o->foo, 2);
is($o->bar, 3);

ok(
	MooseX::XSAccessor::is_xs(Local::Class->can($_)),
	"$_ is XSUB"
) for qw(foo bar);

done_testing;
