=pod

=encoding utf-8

=head1 PURPOSE

Test that sets can have type constraints.

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
use Test::Requires { 'Types::Standard' => '0.014' };
use Test::Fatal;

use Set::Equivalence qw(set);
use Types::Standard qw(-types);

my $set = 'Set::Equivalence'->new(
	type_constraint => HashRef[Int],
	members         => [{}, {}, {}],
);

is($set->type_constraint, HashRef[Int]);

$set->insert({ foo => 1 });

#line 41 "50constraints.t"
my $e = exception { $set->insert({ bar => 1.1 }) };
like($e, qr{did not pass type constraint "HashRef\[Int\]" at 50constraints\.t line 41});

is($set->clone->type_constraint, HashRef[Int]);
is('Set::Equivalence'->clone($set)->type_constraint, undef);

done_testing;
