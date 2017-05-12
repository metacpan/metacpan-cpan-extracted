=head1 PURPOSE

Test that C<< use MooseX::InlineTypes -global >> works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
	package TestClass1;
	
	use Moose;
	use MooseX::InlineTypes -global;
	
	has short_string => (
		is      => 'rw',
		isa     => sub { length($_) <= 5 },
	);
	
	has coerced_short_string => (
		is      => 'rw',
		isa     => sub { length($_) <= 5 },
		coerce  => sub { substr($_, 0, 4) },
	);
	
	has num => (
		is      => 'rw',
		isa     => 'Num',
		coerce  => sub { length("$_") },
	);
	
	has num2 => (
		traits  => [ 'Number' ],
		is      => 'rw',
		isa     => 'Num',
		coerce  => sub { length("$_") },
	);
	
	has num3 => (
		is      => 'rw',
		isa     => 'Num',
		coerce  => [
			Str   => sub { length("$_") },
			Undef => sub { -1 },
			Any   => sub { length("$_") },
		],
	);
	
	has num4 => (
		traits  => [ 'Number' ],
		is      => 'rw',
		isa     => 'Num',
		coerce  => [
			Any   => sub { no warnings; length("$_") },
			Str   => sub { length("$_") },
			Undef => sub { -1 },
		],
	);
	
	has num5 => (
		is      => 'rw',
		isa     => 'Num',
		coerce  => [
			Str   => sub { length("$_") },
			Undef => sub { -1 },
			Any   => sub { length("$_") },
		],
	);
}

my $o = TestClass1->new;
isa_ok($o, 'Moose::Object');

$o->short_string('Foo');
is($o->short_string, 'Foo', 'attribute works');

like(
	exception { $o->short_string('Foolish') },
	qr{^Attribute \(short_string\) does not pass the type constraint},
	'value not meeting constraint dies',
);

is($o->short_string, 'Foo', 'attribute unchanged');

$o->coerced_short_string('Fools');
is($o->coerced_short_string, 'Fools', 'attribute with coercion works');
$o->coerced_short_string('Foolish');
is($o->coerced_short_string, 'Fool', 'attribute with coercion coerces');

$o->num('Fools');
is($o->num, 5, 'attribute with standard Moose type but coercion code');

$o->num2('Foolish');
is($o->num2, 7, 'attribute with standard Moose type but coercion code');

$o->num3('Foolish');
is($o->num3, 7, 'attribute with arrayref coercions - from Str');

$o->num3(undef);
is($o->num3, -1, 'attribute with arrayref coercions - from Undef');

$o->num4('Foolish');
is($o->num4, 7, 'attribute with hashref coercions - from Str');

# Note that "Any" beats "Undef" in the hashref!
$o->num4(undef);
is($o->num4, 0, 'attribute with hashref coercions - from Undef');

$o->num5('Foolish');
is($o->num5, 7, 'attribute with arrayref coercions - from Str');

$o->num5(undef);
is($o->num5, -1, 'attribute with arrayref coercions - from Undef');

done_testing();

