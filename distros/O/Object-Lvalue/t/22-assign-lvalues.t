########################################################################
# housekeeping
########################################################################
package Testify;
use v5.34;
use mro qw( c3 );
use FindBin::libs;

use Test::More;

use List::Util  qw( zip uniq );

my $madness = 'Object::Lvalue';
my @base_methodz
= qw
(
    new
    construct
    initialize

    shallow
    clone

    DESTROY
    cleanup

    class_attr
    attributes

    verbose
);

require_ok $madness;

#$madness->verbose   = 1;

########################################################################
# set up the test packges

my $initialize
= sub
{
    my $obj     = shift;
    $obj->$_    = shift for $obj->attributes;
    $obj
};

# order of inheritence must go down @classdefz.
# this case: two classes share a parent.

my @classdefz   = 
(
    # class  base       attributes

    [ foo => ''  => qw( bar bletch blort    ) ]
  , [ bim => foo => qw( bam                 ) ]
  , [ fee => bim => qw( fie foe fum         ) ]
);

note "Class meta:\n", explain \@classdefz;

for( @classdefz )
{
    local $"    = ' ';
    state $obj  = '$obj';
    state $ISA  = '@ISA';
    state $init = '&$initialize';

    my ( $class, $base, @pkg_attrz ) = @$_;
    note "Install: $class ($base) => @pkg_attrz";

    # install the class itself

    my $pkg = <<"PKG";
package $class;
use v5.34;
BEGIN { our $ISA = qw( $base ) }

use $madness qw( @pkg_attrz );

sub initialize { $init }

1
PKG

    note "$pkg";
    eval qq|$pkg|
    // BAIL_OUT "Failed prepare: $class, $@";
}

########################################################################
# test the packages

$DB::single = 1;

for( @classdefz )
{
    my ( $class ) = $_->[0];

    my @valz    = map { rand } $class->attributes;
    my $obj     = $class->new( @valz );

    for my $attr ( $obj->attributes )
    {
        my $expect  = shift @valz;
        my $found   = $obj->$attr;

        ok $found == $expect, "Found $found ($expect)";
    }
}

pass 'Survived';
done_testing;
__END__
