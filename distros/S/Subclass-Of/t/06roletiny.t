=pod

=encoding utf-8

=head1 PURPOSE

Basic test in Role::Tiny.

=head1 DEPENDENCIES

Test requires Role::Tiny 1.002000 or will be skipped.

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
use Test::Requires { "Role::Tiny" => "1.002000" };
use Test::Fatal;

use Module::Runtime qw(module_notional_filename);

{
	use Subclass::Of "Local::Perl::Class",
		-with     => ["Local::RoleTiny::Role"],
		-methods  => [
			foo => sub { uc(::SUPER()) },
			bar => sub { "BAR" },
			baz => sub { "BAZ" },
		];
	
	my $object = Class->new;
	
	isa_ok($object, 'Local::Perl::Class');
	ok($object->DOES('Local::RoleTiny::Role'), q[$object->DOES('Local::RoleTiny::Role')]);
	can_ok($object, qw[foo bar baz]);
	is($object->foo, 'FOO', q[$object->foo]);
	is($object->bar, 'BAR', q[$object->bar]);
	is($object->baz, 'BAZ', q[$object->baz]);
	
	is($INC{module_notional_filename(Class)}, __FILE__, '%INC ok');
}

ok(!eval "Class; 1", 'namespace::clean worked');

{
	use Subclass::Of "Local::Perl::Class",
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

like(
	exception {
		use Subclass::Of;
		subclass_of("Local::Perl::Class", -has => [ foo => [required => 1] ]);
	},
	qr{^Option 'required' in attribute specification not supported},
);

like(
	exception {
		use Subclass::Of;
		subclass_of("Local::Perl::Class", -has => [ foo => [isa => "Str"] ]);
	},
	qr{^Option 'isa' in attribute specification must be a blessed type constraint object},
);

done_testing;
