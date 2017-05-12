=pod

=encoding utf-8

=head1 PURPOSE

Basic test in Moo.

=head1 DEPENDENCIES

Test requires Moo 1.000000 or will be skipped.

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
use Test::Requires { "Moo" => "1.000000" };

use Module::Runtime qw(module_notional_filename);

{
	use Subclass::Of "Local::Moo::Class",
		-with     => ["Local::Moo::Role"],
		-methods  => [
			foo => sub { uc(::SUPER()) },
			bar => sub { "BAR" },
			baz => sub { "BAZ" },
		];
	
	my $object = Class->new;
	
	isa_ok($object, 'Local::Moo::Class');
	isa_ok($object, 'Moo::Object');
	ok($object->DOES('Local::Moo::Role'), q[$object->DOES('Local::Moo::Role')]);
	can_ok($object, qw[foo bar baz]);
	is($object->foo, 'FOO', q[$object->foo]);
	is($object->bar, 'BAR', q[$object->bar]);
	is($object->baz, 'BAZ', q[$object->baz]);
	
	is($INC{module_notional_filename(Class)}, __FILE__, '%INC ok');
}

ok(!eval "Class; 1", 'namespace::clean worked');

{
	use Subclass::Of "Local::Moo::Class",
		-as  => "MyClass",
		-has => [
			foo    => (),
			bar    => [ is => "ro" ],
			baz    => sub { "BAZ" },
		];
	
	my $o = MyClass->new(foo => 42, bar => 666);
	is($o->foo, 42, '$o->foo');
	is($o->bar, 666, '$o->bar');
	is($o->baz, "BAZ", '$o->baz');
}

done_testing;
