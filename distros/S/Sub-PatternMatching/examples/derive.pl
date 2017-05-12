use strict;
use warnings;
use lib 'lib';
use Sub::PatternMatching 'patternmatch';
use Params::Validate qw/:all/;
no warnings 'once';

my $stringifier = sub {
    my $obj = shift;
    my $str = ref($obj);
    if (@$obj) {
        $str .= '( '
          . join( ', ', map { ref($_) ? $_->stringify : "$_" } @$obj ) . ' )';
    }
    return $str;
};
my $printer = sub { print shift()->stringify, "\n" };
*Product::stringify    = $stringifier;
*Quotient::stringify   = $stringifier;
*Sum::stringify        = $stringifier;
*Difference::stringify = $stringifier;
*Constant::stringify   = $stringifier;
*X::stringify          = $stringifier;
*Product::show         = $printer;
*Quotient::show        = $printer;
*Sum::show             = $printer;
*Difference::show      = $printer;
*Constant::show        = $printer;
*X::show               = $printer;

sub Product    ($$) { bless [ @_[ 0, 1 ] ] => 'Product'    }
sub Quotient   ($$) { bless [ @_[ 0, 1 ] ] => 'Quotient'   }
sub Sum        ($$) { bless [ @_[ 0, 1 ] ] => 'Sum'        }
sub Difference ($$) { bless [ @_[ 0, 1 ] ] => 'Difference' }
sub Constant   ($)  { bless [ $_[0]      ] => 'Constant'   }
sub X          ()   { bless [            ] => 'X'          }

*::derive = patternmatch(
    [ { isa => 'Constant'   } ] => sub { Constant 0 },
    [ { isa => 'X'          } ] => sub { Constant 1 },
    [ { isa => 'Sum'        } ]
        => sub {
       my ( $l, $r ) = @{ $_[0] };
              Sum( derive($l), derive($r) );
           },
    [ { isa => 'Difference' } ]
        => sub {
              my ( $l, $r ) = @{ $_[0] };
              Difference derive($l), derive($r);
           },
    [ { isa => 'Product'    } ]
        => sub {
              my ( $l, $r ) = @{ $_[0] };
              Sum
         Product( derive($l), $r ),
               Product( derive($r), $l );
           }, 
    [ { isa => 'Quotient'   } ]
        => sub {
              my ( $l, $r ) = @{ $_[0] };
              Quotient
              Difference(
                Product( derive($l), $r ),
                Product( derive($r), $l )
              ),
              Product( $r, $r );
           },
);

my $function = Product Constant 5, X;

print "We'll derive this: ";
$function->show;
print "\nThe derivative of the above is computed to:\n";

derive($function)->show;

