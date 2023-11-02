########################################################################
# housekeeping
########################################################################
package Testify;
use v5.34;
use mro qw( c3 );
use FindBin::libs;

use Test::More;

use List::Util  qw( uniq );

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
my %class2attrz = ();

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

    # compte the attribute metadata for testing

    my $class_attrz = $class2attrz{ $class } = {};

    $class_attrz->{ class_attr  } = \@pkg_attrz;
    $class_attrz->{ attributes  } = 
    [
        uniq
        map
        {
            do { $class2attrz{ $_ }{ class_attr } || [] }->@*
        }
        $class->mro::get_linear_isa->@*
    ];
}

note "Attr meta:\n", explain \%class2attrz;

########################################################################
# test the packages

for( @classdefz )
{
    my ( $class ) = $_->[0];

    while
    (
        my ( $method, $expect ) 
        = each $class2attrz{ $class }->%*
    )
    {
        my $found   = $class->$method;

        my $attrs   = join ' ' => @$found;

        is_deeply $found, $expect, "$class $method => $attrs"
        or diag
            "Mismatched $method:\n",
          , "Expect:\n", explain $expect
          ,  "Found:\n", explain $found
        ;
    }
}

pass 'Survived';
done_testing;
__END__
