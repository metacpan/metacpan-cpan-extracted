=pod

=encoding utf-8

=head1 PURPOSE

Test interaction between Moose and Moo classes and roles.

=head1 DEPENDENCIES

Test requires Moose 2.0000 and Moo 1.002000 or will be skipped.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use lib "t/lib";
use lib "lib";

use strict;
use warnings;
use Test::More;
use Test::Requires { "Moose" => "2.0000" };
use Test::Requires { "Moo"   => "1.002000" };

use Module::Runtime qw(module_notional_filename);

{
	use Subclass::Of "Local::Moose::Class",
		-as       => "Class1",
		-with     => ["Local::Moo::Role"],
		-methods  => [
			foo => sub { uc(::SUPER()) },
			bar => sub { "BAR" },
			baz => sub { "BAZ" },
		];
	use Subclass::Of "Local::Moo::Class",
		-as       => "Class2",
		-with     => ["Local::Moose::Role"],
		-methods  => [
			foo => sub { uc(::SUPER()) },
			bar => sub { "BAR" },
			baz => sub { "BAZ" },
		];
	
	my $object1 = Class1->new;
	
	isa_ok($object1, 'Local::Moose::Class');
	isa_ok($object1, 'Moose::Object');
	ok($object1->DOES('Local::Moo::Role'), q[$object1->DOES('Local::Moo::Role')]);
	can_ok($object1, qw[foo bar baz]);
	is($object1->foo, 'FOO', q[$object1->foo]);
	is($object1->bar, 'BAR', q[$object1->bar]);
	is($object1->baz, 'BAZ', q[$object1->baz]);
	
	my $object2 = Class2->new;
	
	isa_ok($object2, 'Local::Moo::Class');
	isa_ok($object2, 'Moo::Object');
	ok($object2->DOES('Local::Moose::Role'), q[$object2->DOES('Local::Moose::Role')]);
	can_ok($object2, qw[foo bar baz]);
	is($object2->foo, 'FOO', q[$object2->foo]);
	is($object2->bar, 'BAR', q[$object2->bar]);
	is($object2->baz, 'BAZ', q[$object2->baz]);
	
	is($INC{module_notional_filename(Class1)}, __FILE__, '%INC ok');
	is($INC{module_notional_filename(Class2)}, __FILE__, '%INC ok');
}

ok(!eval "Class1; 1", 'namespace::clean worked');
ok(!eval "Class2; 1", 'namespace::clean worked');

done_testing;
