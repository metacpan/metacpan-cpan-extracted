=pod

=encoding utf-8

=head1 PURPOSE

Tests method signatures work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

my ($x, $y, $fp, $k);

use MooX::Press::Keywords -all;
use MooX::Press (
	prefix          => 'MyApp',
	factory_package => 'MyApp',
	class => [
		'SomeClass' => { type_name => 'SomeType' },
		'OtherClass' => {
			begin => [
				sub {
					my $class = shift;
					my $reg   = Type::Registry->for_class($class);
					$reg->alias_type('StrLength[1]' => 'Stringo');
				},
			],
			can => {
				'my_method' => {
					optimize  => true,
					signature => [ 'a' => 'SomeType', 'b' => 'Optional[SomeType]', c => 'Stringo' ],
					named     => true,
					code      => sub { my ($self, $args) = @_; uc($args->c) },
				},
				'my_method2' => {
					signature => sub { map int($_), @_ },
					code      => q{sub { my $self = shift; [@_] }},
				},
			},
			factory => [
				'xyzzy' => {
					signature => [ Int, 'SomeType' ],
					named     => false,
					code      => sub { ($fp, $k, $x, $y) = @_; $k->new }
				},
				'new_otherclass',
			],
		},
	],
);

my $obj = MyApp->new_otherclass;
my $e;

$e = exception {
	is($obj->my_method({ a => MyApp->new_someclass, c => 'Yeah' }), 'YEAH', 'returned correct value');
};
is($e, undef, '... and no exception thrown');

$e = exception {
	is($obj->my_method(a => MyApp->new_someclass, b => MyApp->new_someclass, c => 'Woah'), 'WOAH', 'returned correct value');
};
is($e, undef, '... and no exception thrown');

$e = exception {
	is($obj->my_method(a => MyApp->new_someclass, b => MyApp->new_someclass, c => ''), 'BOOP', 'this should not happen');
};
like($e, qr/StrLength.1./);

$e = exception {
	is($obj->my_method(a => MyApp->new_someclass, b => MyApp->new_otherclass, c => 'Boop'), 'BOOP', 'this should not really happen');
};
like($e, qr/did not pass type constraint/);

is_deeply(
	$obj->my_method2(1.1, 2.2, 3.3),
	[1, 2, 3],
);

$obj = MyApp->xyzzy(3, MyApp->new_someclass);
is($x, 3);
is($fp, 'MyApp');
isa_ok($obj, 'MyApp::OtherClass');

my ($xxx, $yyy);
use MooX::Press (
	prefix => 'MyApp2',
	class  => [
		'Base' => {
			can => {
				'my_method' => sub { ++$xxx },
			},
		},
		'Derived' => {
			extends => 'Base',
			before => [
				'my_method' => {
					signature => ['Int'],
					code      => sub { ++$yyy },
				},
			],
		},
		'Derived2' => {
			extends => 'Base',
			around => [
				'my_method' => {
					signature => ['Num'],
					code      => sub {
						return [ map { ref($_)||$_ } @_ ];
					},
				},
			],
		},
	],
);

my $base     = MyApp2->new_base;
my $derived  = MyApp2->new_derived;
my $derived2 = MyApp2->new_derived2;

$base->my_method(42);
$derived->my_method(42);
my $eee = exception {
	$derived->my_method("foo");
};

is($xxx, 2);
is($yyy, 1);
like($eee, qr/did not pass type constraint "?Int"?/);

my $rrr = $derived2->my_method(777);
is_deeply(
	$rrr,
	[ 'CODE', 'MyApp2::Derived2', '777' ],
);

my $fff = exception {
	$derived2->my_method([]);
};
like($fff, qr/did not pass type constraint "?Num"?/);

done_testing;
