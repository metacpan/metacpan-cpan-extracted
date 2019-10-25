=pod

=encoding utf-8

=head1 PURPOSE

Test C<< '+ClassName' >> works.

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

package MyApp;
use Types::Standard qw(Str);
use MooX::Press (
	toolkit => 'Moo',
	role => ['GoodBoi'],
	class => [
		'::Animal' => {
			has => ['$name'],
		},
		'+Dog' => {
			extends => '::Animal',
			with => 'GoodBoi',
			has => ['+$name' => sub { 'Fido' }],
		},
		'+Cat' => {
			extends => '::Animal',
			has => ['$+name' => { default => 'Felix' }],
		},
	],
);

package main;

is(Animal->new->name, undef);
is(Animal::Dog->new->name, 'Fido');
is(Animal::Cat->new->name, 'Felix');
is(Animal::Cat->new(name => 'Milo')->name, 'Milo');

ok(Animal::Dog->does('MyApp::GoodBoi'));

ok exception { Animal->new(name => []) };
ok exception { Animal::Cat->new(name => []) };
ok exception { Animal::Dog->new(name => []) };

done_testing;

