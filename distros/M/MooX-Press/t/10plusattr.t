=pod

=encoding utf-8

=head1 PURPOSE

Test C<< has '+foo' => %spec >> works.

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

use Types::Standard qw(Str);
use MooX::Press (
	toolkit => 'Moo',
	class => [
		'::Animal' => {
			has => ['$name'],
		},
		'::Dog' => {
			extends => '::Animal',
			has => ['+$name' => sub { 'Fido' }],
		},
		'::Cat' => {
			extends => '::Animal',
			has => ['$+name' => { default => 'Felix' }],
		},
	],
);

is(Animal->new->name, undef);
is(Dog->new->name, 'Fido');
is(Cat->new->name, 'Felix');
is(Cat->new(name => 'Milo')->name, 'Milo');

ok exception { Animal->new(name => []) };
ok exception { Cat->new(name => []) };
ok exception { Dog->new(name => []) };

done_testing;

