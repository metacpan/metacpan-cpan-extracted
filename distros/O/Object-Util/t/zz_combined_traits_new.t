=pod

=encoding utf-8

=head1 PURPOSE

Tests that C<< $coderef->$_with_traits(...)->$_new(...) >> works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Requires qw( Moo );

use Object::Util;

{
	package Foo;
	use Moo;
	has foo => (is => "ro");
	has bar => (is => "ro");
}

{
	package Baz;
	use Moo::Role;
	has baz => (is => "ro");
}

my $factory = sub {
	my %args = @_==1 ? %{$_[0]} : @_;
	Foo->new(foo => 42, %args);
};

my $args = { bar => 666, baz => 999 };

{
	my $obj = $factory->$_with_traits("Baz")->$_new($args);
	
	isa_ok($obj, 'Foo', '$obj');
	ok($obj->DOES('Baz'), '$obj DOES Baz');
	can_ok($obj, qw/ foo bar baz /);
	
	is($obj->foo, 42);
	is($obj->bar, 666);
	
	local $TODO = 'could this ever really work?';
	is($obj->baz, 999);
}

{
	my $obj = $factory->$_with_traits("Baz")->$_new($args)->$_clone($args);
	
	isa_ok($obj, 'Foo', '$obj');
	ok($obj->DOES('Baz'), '$obj DOES Baz');
	can_ok($obj, qw/ foo bar baz /);
	
	is($obj->foo, 42);
	is($obj->bar, 666);
	
	is($obj->baz, 999);
}

done_testing;
