=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_isa >>.

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
use Test::Warnings;

{ package Foo; sub new { bless({}, $_[0]) } }
{ package Bar; our @ISA = qw(Foo); sub bar { 1 } }

my $foo = Foo->new;
my $bar = Bar->new;
my $blam = [ 42 ];

ok($foo->isa('Foo'), 'foo isa Foo');
ok($bar->isa('Foo'), 'bar isa Foo');
ok(!eval { $blam->isa('Foo'); 1 }, 'blam goes blam');

use Object::Util;

ok($foo->$_isa('Foo'), 'foo $_isa Foo');
ok($bar->$_isa('Foo'), 'bar $_isa Foo');
ok(eval { $blam->$_isa('Foo'); 1 }, 'no boom today');

done_testing;
