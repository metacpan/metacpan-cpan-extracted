=head1 PURPOSE

Check that the required (C<< ! >>) postfix sigil works, and that the
scalar ((C<< $ >>), array (C<< @ >>) and hash (C<< % >>) prefix sigils
work.

Check that the C<< + >> postfix sigil works, that numbers can default to
values other than zero, and that an explicit C<isa> works.

Make sure that sigils are just hints, and can be overridden by an explicit
attribute spec.

Checks that attribute specs can be hashrefs or arrayrefs.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
use Scalar::Util qw( looks_like_number );
use MooX::Struct
	Structure => [
		qw( $value %dict @list ),
		'@value2' => { isa => sub { die if ref $_[0] } },
		'%list2'  => [ isa => sub { die unless ref $_[0] eq 'ARRAY' } ],
		'$dict2'  => [ isa => sub { die unless ref $_[0] eq 'HASH' } ],
	],
	OtherStructure => [qw( id! ego )],
	Point    => ['+x', '+y' => [default => sub { 101 }]],
	Point3D  => [-extends => ['Point'], '+z' => [isa => sub { die unless looks_like_number($_[0]) || !defined $_[0] }]],
	PointReq => ['+x!', '+y!'],
;

ok eval {
	Structure->new( value => Structure->new )
};

ok eval {
	Structure->new( value => 42 )
};

ok eval {
	Structure->new( list => [] )
};

ok eval {
	Structure->new( dict => +{} )
};

ok eval {
	Structure->new( value2 => "Hello World" );
};

ok eval {
	Structure->new( list2 => [] );
};

ok eval {
	Structure->new( dict2 => {foo => 42} );
};

ok !eval {
	Structure->new( value => [] )
};

ok !eval {
	Structure->new( value => +{} )
};

ok !eval {
	Structure->new( list => 42 )
};

ok !eval {
	Structure->new( dict => 42 )
};

ok !eval {
	Structure->new( value2 => [] );
};

ok !eval {
	Structure->new( list2 => +{} );
};

ok !eval {
	Structure->new( dict2 => 42 );
};

ok eval {
	OtherStructure->new(id => undef);
};

ok !eval {
	OtherStructure->new(ego => undef);
};

my $point = Point->new;
ok defined $point->x;
ok defined $point->y;
is($point->x, 0);
is($point->y, 101);

ok eval {
	Point[ 42, 42 ];
	Point[ 42.1, 42.2 ];
	Point[ "99", "999" ];
	Point[ "+Inf", "-Inf" ];
};

ok not eval {
	Point[ "Hello", "World" ];
};

ok not eval {
	Point[ "", "" ];
};

ok not eval {
	Point[ "Hello", "99" ];
};

ok eval {
	Point3D[ 1, 2 ];
	Point3D[ 1, 2, 3 ];
	Point3D[ 1, 2, undef ];
};

is_deeply(
	Point3D->new->TO_ARRAY,
	[ 0, 101, 0 ],
);

ok not eval {
	Point3D[ 1, 2, "Hello" ];
};

ok eval {
	PointReq[ 1, 2 ];
	PointReq[ 0, '-Inf' ];
	PointReq[ 0, 0 ];
};

ok not eval {
	PointReq[ ];
};

ok not eval {
	PointReq[ "abc", 0 ];
};

done_testing();
