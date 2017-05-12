=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_with_traits >> using Moose objects.

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
use Test::Requires { Moose => '2.0000' };

use Object::Util;

{ package Foo; use Moose::Role; }
{ package Bar; use Moose; with "Foo"; }

my $obj = Bar->$_with_traits("Foo")->new;

ok( $obj->does("Foo") );

done_testing;