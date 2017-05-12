=head1 PURPOSE

Check Sub::NonRole works when a MooseX::Role::Parameterized role is
consumed by a Moose class.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires { 'MooseX::Role::Parameterized' => 0 };

{
	package Local::Role;
	use MooseX::Role::Parameterized;
	use Sub::NonRole;
	parameter value => (isa => 'Int');
	sub a :NonRole { 42 };
	sub b          { 99 };
	role { my $p = shift; method c => sub { $p->value } };
}

{
	package Local::Class;
	use Moose;
	with 'Local::Role' => { value => 101 };
}

can_ok 'Local::Role', 'a';
can_ok 'Local::Role', 'b';
ok(!'Local::Class'->can('a'), 'method hidden correctly');
can_ok 'Local::Class', 'b';
can_ok 'Local::Class', 'c';

is(Local::Class->c, 101);

done_testing;
