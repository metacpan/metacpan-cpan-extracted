=head1 PURPOSE

Check that different structs can inherit from each other.

Check that the "-class" option works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use Test::More;
use MooX::Struct
	Agent        => [ name => undef, -class => \'Local::Test::Class1' ],
	Organisation => [ -extends => ['Agent'], employees => undef, company_number => [is => 'rw']],
	Person       => [ -extends => ['Agent'], -class => [qw/Local Test Class2/] ];

my $alice = Person->new(name => 'Alice');
my $bob   = Person->new(name => 'Bob');
my $acme  = Organisation->new(name => 'ACME', employees => [$alice, $bob]);

note sprintf("Agent class:         %s", Agent);
note sprintf("Person class:        %s", Person);
note sprintf("Organisation class:  %s", Organisation);

is(Agent, 'Local::Test::Class1');
is(Person, 'Local::Test::Class2');
isa_ok($alice, 'Local::Test::Class1');
isa_ok($alice, 'Local::Test::Class2');

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

isa_ok($alice, Agent);
isa_ok($bob, Agent);
isa_ok($acme, Agent);
isa_ok($alice, Person);
isa_ok($bob, Person);
isa_ok($acme, Organisation);
isa_ok(Organisation, Agent);
isa_ok(Person, Agent);

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


use MooX::Struct XXX1 => [ qw< $foo > ];
use MooX::Struct XXX2 => [ -extends => [ XXX1 ], qw< $bar > ];

is_deeply([XXX2->FIELDS], [qw< foo bar >]);

done_testing;
