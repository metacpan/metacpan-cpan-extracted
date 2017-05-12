=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_extend >> with L<Mouse>.

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
use Test::Requires { Mouse => '1.00' };

use Object::Util;

{
	package Local::Class;
	use Mouse;
}

my $obj1 = Local::Class->new;
my $obj2 = Local::Class->new;

for ($obj1, $obj2) {
	$_->$_extend(
		foo => sub { 666 },
		bar => sub { 999 },
	);
}

is(
	ref($obj1),
	ref($obj2),
	'eigenclass cache',
);

isa_ok($_, "Local::Class") for $obj1, $obj2;

is($_->foo, 666) for $obj1, $obj2;
is($_->bar, 999) for $obj1, $obj2;

$obj2->$_extend(baz => sub { 111 });

isnt(
	ref($obj1),
	ref($obj2),
	'eigenclass cache',
);

isa_ok($obj2, ref($obj1));

ok(!$obj1->can("baz"));
is($obj2->baz, 111);

{
	package MyRole;
	use Mouse::Role;
	sub xxx { 1 }
	sub yyy { 2 }
	sub zzz { 3 }
}

my $obj = $obj1->$_extend(['MyRole']);

is($obj, $obj1);
ok($obj->DOES('MyRole'));
ok(!$obj2->DOES('MyRole'));
isa_ok($obj, 'Local::Class');
is($obj->xxx, 1);
is($obj->yyy, 2);
is($obj->zzz, 3);

my $class = ref($obj);
$obj->$_extend();
is(ref($obj), $class);

done_testing;
