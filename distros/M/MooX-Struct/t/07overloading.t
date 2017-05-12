=head1 PURPOSE

Check that overloading to string and to arrayref work.

Also checks the C<CLONE> method.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
use MooX::Struct
	Point   => [ qw(x y) ],
	Point3D => [ -extends => [qw(Point)], qw(z) ],
;

my $point = Point->new(x => 3, y => 4);
is("$point", "3 4", "Point stringifies correctly");

my $point2 = Point3D->new(x => 3, y => 4, z => 5);
is("$point2", "3 4 5", "Point3D stringifies correctly");

is_deeply( [ @$point2 ], [qw(3 4 5)], "Point3D casts to array properly" );

my $clone = CLONE $point2;
is("$clone", "3 4 5", "cloning is awesome");

done_testing;
