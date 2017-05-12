=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_with_traits >> using Mouse objects.

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
#use Test::Warnings;
use Test::Requires { Mouse => '1.00' };

use Object::Util;

{ package Foo; use Mouse::Role; }
{ package Bar; use Mouse; with "Foo"; }

my $obj = Bar->$_with_traits("Foo")->new;

ok( $obj->does("Foo") );

done_testing;
