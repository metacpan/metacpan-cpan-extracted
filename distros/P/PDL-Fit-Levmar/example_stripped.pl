use Data::Dumper;
use PDL;
use PDL::Fit::Levmar;
use PDL::NiceSlice;
use PDL::Core ':Internal'; # For topdl()



$t = (sequence(10) -5);
$x = 3 * exp(-$t*$t * .3  );
$p = [ 1, 1 ]; # initial guesses
print levmar($p,$x,$t, FUNC =>
          '   function gaussian
              x = p0 * exp( -t*t * p1);
           ')->{REPORT};
