=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::XSAccessor works OK with L<MooseX::Attribute::Chained>.

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
use Test::Requires { "MooseX::Attribute::Chained" => "0" };

{
	package Local::Class;
	use Moose;
	use MooseX::XSAccessor;
	use MooseX::Attribute::Chained;
	
	my $Chained = ['MooseX::Traits::Attribute::Chained'];
	
	has foo => (is => "rw", traits => $Chained);
	has bar => (is => "ro", traits => $Chained, writer => "_set_bar");
	has baz => (is => "rw");
	
	sub quux { 42 };
}

my $o = "Local::Class"->new(foo => 1, bar => 2);

ok($o->meta->get_attribute('foo')->does('MooseX::XSAccessor::Trait::Attribute'));
ok($o->meta->get_attribute('foo')->does('MooseX::Traits::Attribute::Chained'));

is($o->foo(3)->quux, 42, 'accessor can be chained');
is($o->foo, 3, 'chaining set new value');

is($o->_set_bar(4)->quux, 42, 'writer can be chained');
is($o->bar, 4, 'chaining set new value');

is($o->baz(5), 5, 'non-chained accessor in a chained world');

ok(
	MooseX::XSAccessor::is_xs(Local::Class->can($_)),
	"$_ is XSUB"
) for qw(foo bar baz _set_bar);

done_testing;
