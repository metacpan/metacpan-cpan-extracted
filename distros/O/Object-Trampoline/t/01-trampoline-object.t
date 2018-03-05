use v5.24;

use Object::Trampoline;

use Test::More;
use Scalar::Util    qw( blessed reftype );

# create three trampolines. note that "frobnicate" is the
# constructor for each of them.

my $ot  = 'Object::Trampoline';
my $otb = 'Object::Trampoline::Bounce';

my $abc = $ot->frobnicate( 'abc', foo => 'bar' );
my $ijk = $ot->frobnicate( 'ijk', foo => 'bar' );
my $xyz = $ot->frobnicate( 'xyz', foo => 'bar' );

# at this point all three objects are blessed into O::T::Bounce.

for my $obj ( $abc, $ijk, $xyz )
{
    state $blessed  = Scalar::Util->can( 'blessed' );
    
    my $pkg = $obj->$blessed;

    is $pkg, $otb, "obj isa '$pkg' ($otb)";
}

# at this point a method is called using the objects. this 
# converts them from O::T::B into whatever would've been 
# constructed in the first place by the original calls to 
# the constructor ("frobnicate").

my $abc_expect  = $abc->foo;
my $ijk_expect  = $ijk->bar;
my $xyz_expect  = $xyz->baz;

# at this point all three objects should be 
# blessed into their respective classes.
#
# two sanity checks: the ref's have changed
# and they each have different data structures.

my $abc_class   = blessed $abc;
my $ijk_class   = blessed $ijk;
my $xyz_class   = blessed $xyz;

my $abc_type    = reftype $abc;
my $ijk_type    = reftype $ijk;
my $xyz_type    = reftype $xyz;

my $abc_found   = eval { $abc->{ foo }      };
my $ijk_found   = eval { $ijk->[ 1 ]        };
my $xyz_found   = eval { ( $xyz->() )[1]    };

is $abc_class, $abc_expect, "abc is '$abc_class' ($abc_expect)";
is $ijk_class, $ijk_expect, "ijk is '$ijk_class' ($ijk_expect)";
is $xyz_class, $xyz_expect, "xyz is '$xyz_class' ($xyz_expect)";

ok $abc_type  eq 'HASH' , "abc is $abc_type (HASH)";
ok $ijk_type  eq 'ARRAY', "ijk is $ijk_type (ARRAY)";
ok $xyz_type  eq 'CODE' , "xyz is $xyz_type (CODE)";

is $abc_found, 'bar', 'abc {foo} is bar';
is $ijk_found, 'bar', 'ijk [1]   is bar';
is $xyz_found, 'bar', 'xyz returns  bar';

{
    package abc;

    sub frobnicate
    {
        my $proto = shift;
        
        bless { @_ }, $proto
    }

    sub foo { __PACKAGE__ }


    package ijk;

    sub frobnicate
    {
        my $proto = shift;
        
        bless [ @_ ], $proto
    }


    sub bar { __PACKAGE__ }


    package xyz;

    sub frobnicate
    {
        my $proto = shift;

        my @a = @_;
        
        bless sub{ @a }, $proto
    }


    sub baz { __PACKAGE__ };
}

done_testing;

__END__
