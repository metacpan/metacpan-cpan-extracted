=head1 PURPOSE

Basic MooX::Struct usage.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use Test::More tests => 18;
use MooX::Struct
	Organisation => [qw/ name employees /, company_number => [is => 'rw']],
	Person       => [qw/ name /];

my $alice = Person->new(name => 'Alice');
my $bob   = Person->new(name => 'Bob');
my $acme  = Organisation->new(name => 'ACME', employees => [$alice, $bob]);

note sprintf("Person class:        %s", Person);
note sprintf("Organisation class:  %s", Organisation);

is(
	ref($alice),
	ref($bob),
	'Alice and Bob are in the same class',
);

isnt(
	ref($alice),
	ref($acme),
	'Alice and ACME are not in the same class',
);

isa_ok($_, 'MooX::Struct', '$'.lc($_->name)) for ($alice, $bob, $acme);

is($alice->name, 'Alice', '$alice is called Alice');
is($bob->name, 'Bob', '$bob is called Bob');
is($acme->name, 'ACME', '$acme is called ACME');

ok !eval {
	$acme->name('Acme Inc'); 1
}, 'accessors are read-only by default';

$acme->company_number(12345);
is($acme->company_number, 12345, 'accessors can be made read-write');

can_ok $alice => 'OBJECT_ID';
isnt($alice->OBJECT_ID, $bob->OBJECT_ID, 'OBJECT_ID is unique identifier');

isa_ok($_->TYPE_TINY, 'Type::Tiny', '$'.lc($_->name).'->TYPE_TINY') for ($alice, $bob, $acme);
ok($_->TYPE_TINY->check($_), '$'.lc($_->name).'->TYPE_TINY->check') for ($alice, $bob, $acme);
