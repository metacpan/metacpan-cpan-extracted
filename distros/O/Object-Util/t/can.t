=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_can >>.

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

ok(!$foo->can('bar'), 'foo !can bar');
ok($bar->can('bar'), 'bar can bar');
ok(!eval { $blam->can('bar'); 1 }, 'blam goes blam');

use Object::Util;

ok(!$foo->$_can('bar'), 'foo !$_can bar');
ok($bar->$_can('bar'), 'bar $_can bar');
ok(eval { $blam->$_can('bar'); 1 }, 'no boom today');

ok($bar->$_can(sub { 42 }), '$object->$_can($coderef)');

done_testing;
