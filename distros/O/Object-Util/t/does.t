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
use Test::Requires { Moo   => '1.000000' };

use Object::Util;

{ package Foo; use Moo::Role; }
{ package Bar; use Moo; with "Foo"; }

my $bar = Bar->new;
my $blam = [ 42 ];

ok($bar->does('Foo'), 'bar does Foo');
ok(!eval { $blam->does('Foo'); 1 }, 'blam goes blam');

ok($bar->$_does('Foo'), 'bar $_does Foo');
ok(eval { $blam->$_does('Foo'); 1 }, 'no boom today');

done_testing;
