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
use constant SYMBOLS   => ['', 'i' .. 'z', map('a' . $_, ('a' .. 'z')), ( map('b' . $_, ('a' .. 'z')) ) x 100];



#
# Conjugate: z* = (a,b)* = (-a,b*)
#
sub conjugate {
   my $m = shift;

   my $a = ref $m->a ? $m->a->conjugate : $m->a;
   my $b = - $m->b;
   (ref $m)->new($a, $b)
}



# 
# Invert: 1/z = z⁻¹ = (a,b)⁻¹ = (a,b)*/(norm(a,b)²)
#
sub inverse {
   my $m  = shift;

   my $conjugate = $m->conjugate;
   my $norm = $m->norm;
   $conjugate / $norm ** 2
}



# 
# Norm: z->norm = √(norm(a)²+norm(b)²) and norm(number) = number
#
sub norm {
   my $m = shift;

   my $a = ref $m->a ? $m->a->norm : $m->a;
   my $b = ref $m->b ? $m->b->norm : $m->b;
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

   my ( $a, $b, $c, $cs, $d, $ds, $g );
   return $m * $o if $swap;
   $g = $m->gamma;
   $a = $m->a;
   $b = $m->b;
   if (ref $o) {
      $c  = $o->a;
      $d  = $o->b;
      $cs = ref $o->a ? $o->a->conjugate : $o->a;
      $ds = ref $o->b ? $o->b->conjugate : $o->b
   }
   else {
      $c = $cs = $o;
      $d = $ds = 0
   }
   (ref $m)->new($a * $c + $g * $ds * $b, $d * $a + $b * $cs)
}



# 
# Tensor: $a->tensor($b) = A⊗ B = (a,b)⊗ (c,d) = (ac,ad,bc,bd)
#
# sub tensor { (ref $m)->new( ref $m->a ? ($m->a->tensor($o), $m->b->tensor($o)) : ($m->a * $o, $m->b * $o) ) }
sub tensor {
   my ( $m, $o ) = @_;

   if (ref $m->a) {
      (ref $m)->new($m->a->tensor($o), $m->b->tensor($o))
   }
   else {
      (ref $m)->new($m->a * $o, $m->b * $o)
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
sub a { ${(shift)}[0] }
sub b { ${(shift)}[1] }



#
# flat: list of the scalar values pointed to by a,b references in the object references in order ...
#
sub flat {
   my $m = shift;
   (ref $m->a ? flat($m->a) : $m->a), (ref $m->b ? flat($m->b) : $m->b)
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
# Gamma: algebra selection: -1=cayley-dickson, 0=dual complex, 1=split complex
#
sub gamma { -1 }



# 
# additional meta tools ...
#
sub is_complex                    { not ( shift )->_child_is('complex'                  ) }
sub is_quaternion                 {     ( shift )->_child_is('complex'                  ) }
sub is_octonion                   {     ( shift )->_child_is('quaternion'               ) }
sub is_sedenion                   {     ( shift )->_child_is('octonion'                 ) }
sub is_trigintaduonions           {     ( shift )->_child_is('sedenion'                 ) }
sub is_sexagintaquatronions       {     ( shift )->_child_is('trigintaduonions'         ) }
sub is_centumduodetrigintanions   {     ( shift )->_child_is('sexagintaquatronions'     ) }
sub is_ducentiquinquagintasexions {     ( shift )->_child_is('centumduodetrigintanions' ) }



#
# determine if the child is of the given type by common cayley dickson name ...
#
sub _child_is {
   my $a = (shift)->a;
   my $f = 'is_' . (shift);
   ref $a and $a->can($f) and $a->$f
}



################################################
# ... Cayley-Dickson algebriac functions ...
#
# Generate a new 
#
# Conjugate: z* = (a,b)* = (-a,b*)
#
# Invert: 1/z = z⁻¹ = (a,b)⁻¹ = (a,b)*/(norm(a,b)²)
#
# Norm: z->norm = √(norm(a)²+norm(b)²) 
#
# norm(number) = number
#
# Addition: z1+z2 = (a,b)+(c,d) = (a+c, b+d)
#
# Subtraction: (a,b)-(c,d) = (a-c, b-d)
# $s: swap flag. Tells us that the calculation was like "2-(0,1)" but we received it in reverse order.
#
# Divide: z1/z2 = (a,b) × (c,d)⁻¹ = (a,b) × inverse(c,d)
#   ... invert the divisor and then use multiplication instead.
# Divide: (a,b)/n = (a,b) × 1/n
#   ... if the divisor is just a number, invert it and use multiplication instead.
# $s: swap flag. Tells us that the calculation was like "2/(0,1)" but we received it in reverse order.
#
# Multiply: (a,b)×(c,d) = (ac-d*b,da+bc*)
# ... where z* represents the conjugate(z) where z is not a number.
# ... where n* = n when n is a number.
# $s: swap flag. Tells us that the calculation was like "2*(0,1)" but we received it in reverse order.
#
# Tensor: A⊗ B = (a,b)⊗ (c,d) => A = (ac, db, da, bc), B = (ac,bc,db,da)
# given two object, move them into seperate spaces and tensor them,
# so that their partial products are shared in memory...
# Object construction, manipulation and debugging tools ...
#
# Standard POD documentation coming soon.

1;

__END__

