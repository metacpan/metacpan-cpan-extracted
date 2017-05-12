=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_DOES >>.

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

use Object::Util;

{ package Foo; sub new { bless({}, $_[0]) } }
{ package Bar; our @ISA = qw(Foo); sub bar { 1 } }

my $foo = Foo->new;
my $bar = Bar->new;
my $blam = [ 42 ];

ok($foo->DOES('Foo'), 'foo DOES Foo');
ok($bar->DOES('Foo'), 'bar DOES Foo');
ok(!eval { $blam->DOES('Foo'); 1 }, 'blam goes blam');

ok($foo->$_DOES('Foo'), 'foo $_DOES Foo');
ok($bar->$_DOES('Foo'), 'bar $_DOES Foo');
ok(eval { $blam->$_DOES('Foo'); 1 }, 'no boom today');

done_testing;
