#
# CayleyDickson.pm - Cayley-Dickson constructions and algebriac manipulations
#
#   author: Jeffrey B Anderson - truejeffanderson at gmail.com
#
#     reference: https://en.wikipedia.org/wiki/Cayley-Dickson_construction
#


package CayleyDickson;
use strict;
no  warnings;
use overload qw(- subtract + add * multiply / divide "" as_string eq eq);
use constant SYMBOLS => ['', 'i' .. 'z', map('a' . $_, ('a' .. 'z')), ( map('b' . $_, ('a' .. 'z')) ) x 100];
our $VERSION = 0.03;

# logic numbers ...
use constant YES => 1;
use constant NO  => 0;

use constant DOUBLING_PRODUCT => 'Pt0';
#
# multiplication rules for (a,b)×(c,d)
#  valid DOUBLING PRODUCT options... 
#
#  P0  =>  (  c×a - B×d , d×A + b×c  )
#  P1  =>  (  c×a - d×B , A×d + c×b  )
#  P2  =>  (  a×c - B×d , d×A + b×c  )
#  P3  =>  (  a×c - d×B , A×d + c×b  )
# Pt0  =>  (  c×a - b×D , a×d + C×b  ) # default/tested
# Pt1  =>  (  c×a - D×b , d×a + b×C  )
# Pt2  =>  (  a×c - b×D , a×d + C×b  )
# Pt3  =>  (  a×c - D×b , d×a + b×C  )
#
# ...where lower and upper case are conjugate vectors.
# ref: http://jwbales.us/cdproducts.html

use constant I_SQUARED => -YES;
#
# I_SQUARED is the square of the first imaginary unit i. Valid options:
#
#  1  =>  Split numbers
#  0  =>  Dual numbers
# -1  =>  Cayley-Dickson numbers # default/tested



#
# Conjugate: z* = (a,b)* = (a*,-b)
#
sub conjugate {
   my $m = shift;

   my $a_conjugate = $m->is_complex ? $m->a : $m->a->conjugate;
   my $negative_b  = -$m->b;

   (ref $m)->new($a_conjugate, $negative_b)
}



# 
# Invert: 1/z = z⁻¹ = (a,b)⁻¹ = (a,b)*/(norm(a,b)²)
#
sub inverse {
   my $m  = shift;

   my $conjugate = $m->conjugate;
   my $norm      = $m->norm;
   $conjugate / $norm ** 2
}


sub d {
   my %a = @_;
   my @k = keys %a;
   my $d = Data::Dumper->new([@a{@k}],[@k]); $d->Purity(1)->Deepcopy(1); print $d->Dump;
}



# 
# Norm: z->norm = √(norm(a)²+norm(b)²) and norm(number) = number
#
sub norm {
   my $m = shift;

   my $a = $m->is_complex ? $m->a : $m->a->norm;
   my $b = $m->is_complex ? $m->b : $m->b->norm;

   sqrt($a ** 2 + $b ** 2)
}



# 
# Addition: z1+z2 = (a,b)+(c,d) = (a+c,b+d)
#
sub add {
   my ( $m, $o ) = @_;

   my $a = $m->a;
   my $b = $m->b;
   my $c = $o->a;
   my $d = $o->b;

   (ref $m)->new($a + $c, $b + $d)
}



# 
# Subtraction: (a,b)-(c,d) = (a-c,b-d)
#
sub subtract {
   my ( $m, $o, $swap ) = @_;

   $o = (ref $m)->new((my $v = $o), 0) unless ref $o;

   my $a = $swap ? $o->a : $m->a;
   my $b = $swap ? $o->b : $m->b;
   my $c = $swap ? $m->a : $o->a;
   my $d = $swap ? $m->b : $o->b;

   (ref $m)->new($a - $c, $b - $d)
}



# 
# Divide: z1/z2 = (a,b) × (c,d)⁻¹ = (a,b) × inverse(c,d)
#
sub divide {
   my ( $m, $o, $swap ) = @_;

   my ( $a, $b );
   $a = $swap ? $m->inverse : $m;
   $b = $swap ? $o : (ref $o ? $o->inverse : ($o ? 1 / $o : 0));

   $a * $b
}



# 
# Multiply: (a,b)×(c,d) = (a×c - d*×b, d×a + b×c*) where x* = conjugate(x) or x if x is a number
#
sub multiply {
   my ( $m, $o, $swap ) = @_;

   # Ignore $swap since n×c = c×n when n is a number and the reason why swap would be set.
   
   my ( $ii, $a, $as, $b, $bs, $c, $cs, $d, $ds );

   $ii = $m->i_squared;
   $a  = $m->a;
   $b  = $m->b;
   if (ref $o) {
      $c  = $o->a;
      $d  = $o->b;
      if ($m->is_complex) {
         $as = $a;
         $bs = $b;
      }
      else {
         $as = $m->a->conjugate;
         $bs = $m->b->conjugate;
      }
      if ($o->is_complex) {
         $cs = $c;
         $ds = $d;
      }
      else {
         $cs = $o->a->conjugate;
         $ds = $o->b->conjugate;
      }
   }
   else {
      $c  = $o;
      $d  =  0;
      if ($m->is_complex) {
         $as = $a;
         $bs = $b;
      }
      else {
         $as = $a->conjugate;
         $bs = $b->conjugate;
      }
      $cs = $o;
      $ds =  0;
   }

   # the eight ways to multiply Cayley Dickson number constructions...
   #
   my $dp = $m->doubling_product;
   if    ($dp eq 'P0' ) { (ref $m)->new($c * $a + $ii * $bs *  $d,  $d * $as +  $b *  $c) }
   elsif ($dp eq 'P1' ) { (ref $m)->new($c * $a + $ii *  $d * $bs, $as *  $d +  $c *  $b) }
   elsif ($dp eq 'P2' ) { (ref $m)->new($a * $c + $ii * $bs *  $d,  $d * $as +  $b *  $c) }
   elsif ($dp eq 'P3' ) { (ref $m)->new($a * $c + $ii *  $d * $bs, $as *  $d +  $c *  $b) }
   elsif ($dp eq 'Pt0') { (ref $m)->new($c * $a + $ii *  $b * $ds,  $a *  $d + $cs *  $b) } # <= default
   elsif ($dp eq 'Pt1') { (ref $m)->new($c * $a + $ii * $ds *  $b,  $d *  $a +  $b * $cs) }
   elsif ($dp eq 'Pt2') { (ref $m)->new($c * $a + $ii *  $b * $ds,  $a *  $d + $cs *  $b) }
   elsif ($dp eq 'Pt3') { (ref $m)->new($a * $c + $ii * $ds *  $b,  $d *  $a +  $b * $cs) }
}



# 
# Tensor: $a->tensor($b) = A⊗ B = (a,b)⊗ (c,d) = (ac,ad,bc,bd)
#
sub tensor {
   my ( $m, $o ) = @_;

   if ($m->is_complex) {
      (ref $m)->new($m->a * $o, $m->b * $o)
   }
   else {
      (ref $m)->new($m->a->tensor($o), $m->b->tensor($o))
   }
}



#
# Creates a new CayleyDickson object
#   provide a list of two (or any 2^n) numbers or objects ...
#
sub new {
   my $c = shift;
   my $n = scalar @_;
   my @pair = $n > 2 ? ($c->new(@_[0 ..$n/2-1]),$c->new(@_[$n/2 ..$n-1])) : @_[0,1];
   bless [@pair] => $c
}



#
# hold the left number/object in a and the right number/object in b.
#
sub a { ${(shift)}[NO ] }
sub b { ${(shift)}[YES] }



#
# flat: list of the scalar values pointed to by a,b references in the object references in order ...
#
sub flat {
   my $m = shift;
   $m->is_complex ? ($m->a, $m->b) : ($m->a->flat, $m->b->flat);
}


# 
# print the beautiful objects in terse human format ...
#
sub as_string {
   my ( $m, $i, $swap ) = ( shift, 0, '' );

   foreach my $t ($m->flat) {
      if ($t or not $i) {
        $swap .= sprintf '%s%s%s', ($t < 0 ? '-' : '+'), abs($t), ${ SYMBOLS() }[$i]
      }
      $i ++
   }
   $swap
}



#
# compare the string format of this object to the given string
#
sub eq { shift->as_string eq shift }



# 
# override these methods to test other algebras or the dual and split number systems ...
#
# doubling_product:See DOUBLING constant above for option choices. Override this method in your subclass if you like.
#
# i_squared: algebra selection. See I_SQUARED constant above for option choices. Override this method in your subclass if you like.
#
#
sub doubling_product { DOUBLING_PRODUCT }
sub i_squared        { I_SQUARED        }



# 
# additional meta tools ...
#
sub is_real                       { NO } # you could not be here if you are real 
sub is_complex                    { not ref (shift->a) }
sub is_quaternion                 { shift->_child_is('is_complex'                  ) }
sub is_octonion                   { shift->_child_is('is_quaternion'               ) }
sub is_sedenion                   { shift->_child_is('is_octonion'                 ) }
sub is_trigintaduonions           { shift->_child_is('is_sedenion'                 ) }
sub is_sexagintaquatronions       { shift->_child_is('is_trigintaduonions'         ) }
sub is_centumduodetrigintanions   { shift->_child_is('is_sexagintaquatronions'     ) }
sub is_ducentiquinquagintasexions { shift->_child_is('is_centumduodetrigintanions' ) }
#sub is_etc ...


#
# determine if the child is of the given type by common cayley dickson name ...
#
sub _child_is {
   my $m      = shift;
   my $method = shift;
   not $m->is_complex and $m->a->can($method) and $m->a->$method;
}

=encoding utf8

=pod

=head1 NAME

CayleyDickson - create and operate with hypercomplex numbers

=head1 SYNOPSIS

=over 4

 use Tangle;
 my $q1 = Tangle->new(1,0);
 print "q1 = $q1\n";
 $q1->x_gate;
 print "X(q1) = $q1\n";
 $q1->hadamard;
 print "H(X(q1)) = $q1\n";

 my $q2 = Tangle->new(1,0);
 print "q2 = $q2\n";

 # perform CNOT($q1 ⊗ $q2)
 $q1->cnot($q2);

 print "q1 = $q1\n";
 print "q2 = $q2\n";

 $q1->x_gate;
 print "X(q1) = $q1\n";
 print "entanglement causes q2 to automatically changed: $q2\n";

=back

=head1 DESCRIPTION

=over 3

 Cayley-Dickson construction and operations are defined here: https://en.wikipedia.org/wiki/Cayley–Dickson_construction

 This object provides natural and intuitive operations on these numbers by overriding the native numeric operations (+,-,/,*)

=back

=head1 USAGE


=head2 new()

=over 3

 # create a new CayleyDickson number "i" ...
 my $q1 = CayleyDickson->new(0,1);


 # create a new CayleyDickson number "1+2i+3j+4k" ...
 my $q2 = CayleyDickson->new(1,2,3,4);


 # create a bigger CayleyDickson number (a Sedenion) ...
 my $q3 = CayleyDickson->new(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16);


 # create a CayleyDickson number from others ...
 my $one  = CayleyDickson->new(0,1);
 my $zero = CayleyDickson->new(1,0);
 my $quaternion = CayleyDickson->new($one,$zero);

=back

=head2 conjugate()

=over 3

   if z = (a,b)
 then conjugate z = z* = (a,b)* = (a*,-b)
   or conjugate(number) = number
 
 printf "The conjugate of q1 is: %s\n", $q1->conjugate;

=back

=head2 inverse()

=over 3

   if z = (a,b)
 then inverse z = z⁻¹ = (a,b)⁻¹ = (a,b)*/(norm(a,b)²)
   or inverse(number) = number
 
 printf "The inverse of q1 is: %s\n", $q1->inverse;

=back

=head2 norm()

=over 3

   if z = (a,b)
 then norm z = norm(a,b) = √(norm(a)²+norm(b)²)
   or norm(number) = number
 
 printf "The norm of q1 is: %s\n", $q1->norm;

=back

=head2 add()

=over 3

 # ass z1 + z2 = (a,b)+(c,d) = (a+c,b+d)
 
 printf "The sum of q1 + q2 is: %s\n", $q1 + $q2;

=back

=head2 subtract()

=over 3

 # subtract z1 - z2 =  (a,b)-(c,d) = (a-c,b-d)

 printf "The difference of q1 - q2 is: %s\n", $q1 - $q2;

=back

=head2 divide()

=over 3

 # divide z1 / z2 = z1 × inverse(z2)
 
 printf "The division of q1 / q2 is: %s\n", $q1 / $q2;

=back

=head2 multiply()

=over 3

 # Multiply: (a,b)×(c,d) = (a×c - d*×b, d×a + b×c*) where x* = conjugate(x) or x if x is a number

 printf "The product of q1 * q2 is: %s\n", $q1 * $q2;

=back

=head2 new()

=over 3

  create a new CayleyDickson number of any size ...

  # create the number 1+j-k ...
  my $c = CayleyDickson->new( -1, 0, 1, -1 );

  # create an octonion ...
  my $c = CayleyDickson->new( 3, 7, -2, 8, 0, 3, 3, 5 );

  # create a representation of the Horne bell state |+-> ...
  my $c = CayleyDickson->new( 1/2, 1/2, 1/2 ,-1/2 );

  # create a 128 number construction: 1+2i+3j+4k+ .. + 128 ....
  my $c = CayleyDickson->new(1 .. 128);

=back

=head2 tensor()

=over 3

 Tensors two Cayley Dickson numbers to calculate a new number of higher dimensional construction.
 reference: https://en.wikipedia.org/wiki/Tensor_product

 # calculate the tensor of c1 ⊗  c2 ...
 $d = $c1->tensor($c2);

 $d will be a number of the product of the dimensions of c1 and c2.

=back

=head2 a()

=head2 b()

=over 3

 returns the two objects or numbers held by this object

=back

=head2 flat()

=over 3

 return all the coefficients of the number as an array
 
 printf "[%s]\n", join( ', ', $q1->flat); 


=back

=head2 as_string()

=over 3

 called automatically when this object is requested in a string form.
 if you want to force the object to be resolved as a string ...

 printf "q1 as a string = %s\n", $q1->as_string;

=back

=head2 i_squared()

=over 3

   returns the square of i: i² = -1

   normally this will be -1, but you can change it to +1 or 0 using the constant I_SQUARED



=back

=head2 doubling_product()

=over 3

 something

=back

=head2 is_complex()

=head2 is_quaternion()

=head2 is_octonion()

=head2 is_sedenion()

=head2 is_trigintaduonions()

=head2 is_sexagintaquatronions()

=head2 is_centumduodetrigintanions()

=head2 is_ducentiquinquagintasexions()

 returns true if the given object has depth equal to the function name

 if ($q1->is_octionion) {
    print "q1 is an Octonion\n";
 }
 else {
    print "q1 is NOT an Octonion\n";
 }

=back

=head1 SUMMARY

=over 3

 This object holds Cayley Dickson numbers and provides math operations on them.

 =back

=head1 AUTHOR

 Jeff Anderson
 truejeffanderson@gmail.com

=cut


1;

__END__

