=head1 PURPOSE

Check square-bracket-style constructor.

Also checks constructor called with a hashref (works, but not officially
supported).

Tests that objects overloading both hash and array are considered to be
hashrefs by the constructor, not arrayrefs.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
use MooX::Struct
	Point   => [ qw( +x +y ) ],
	Point3D => [ -extends => [qw(Point)], qw( +z ) ],
;

my $point1 = Point[3, 4];
my $point2 = Point3D[3, 4, 5];
my $point3 = Point3D[3, 4];

is("$point1", "3 4");
is("$point2", "3 4 5");
is("$point3", "3 4 0");

is(
	Point3D->new([3, 4, 5])->TO_STRING,
	"3 4 5",
);

is(
	Point3D->new({ z=>1, y=>2, x=>3, y=>4, z=>5 })->TO_STRING,
	"3 4 5",
);

ok not eval {
	Point3D->new( \*STDERR )
};

ok not eval {
	Point3D[1, 2, 3, 4]
};

{
	package Local::WeirdHash;
	use overload '@{}' => 'TO_ARRAY';
	sub TO_ARRAY {
		my $self = shift;
		[ sort keys %$self ];
	}
}

my $weird = bless { z=>1, y=>2, x=>3, y=>4, z=>5 }, 'Local::WeirdHash';
is(
	Point3D->new($weird)->TO_STRING,
	"3 4 5",
	'if constructed with an object that "does" array and hash, hash is preferred',
);

done_testing();
