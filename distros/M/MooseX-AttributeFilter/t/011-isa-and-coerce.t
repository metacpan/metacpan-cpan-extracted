use strict;
use warnings;
use Test2::V0;

BEGIN {
    eval { require Types::Standard }
        or plan skip_all => 'Types::Standard not available';
};

plan tests => 4;

{
    package Foo;
    use Moose;
    use MooseX::AttributeFilter;
    use Types::Standard -types;
    
    has attr => (
        is      => 'rw',
        isa     => Int->plus_coercions( Num, q(int($_)) ),
        filter  => sub { 10 * $_[1] },
        coerce  => 1,
    );
}

my $immutable = "mutable";
for (0 .. 1) {
    my $obj = Foo->new(attr => 12.345);
    is( $obj->attr, 123, "constructor coercions happen after filter ($immutable class)" );
    $obj->attr(98.765);
    is( $obj->attr, 987, "accessor coercions happen after filter ($immutable class)" );
    
    $immutable = "immutable";
    Foo->meta->make_immutable;
};
