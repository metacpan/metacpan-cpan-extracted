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
			can => {
				'my_method' => {
					signature => [ 'a' => 'SomeType', 'b' => 'Optional[SomeType]', c => 'Str' ],
					named     => true,
					code      => sub { my ($self, $args) = @_; uc($args->c) },
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
	is($obj->my_method(a => MyApp->new_someclass, b => MyApp->new_otherclass, c => 'Boop'), 'BOOP', 'this should not really happen');
};
like($e, qr/did not pass type constraint/);

$obj = MyApp->xyzzy(3, MyApp->new_someclass);
is($x, 3);
is($fp, 'MyApp');
isa_ok($obj, 'MyApp::OtherClass');

done_testing;

