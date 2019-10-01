#
# CayleyDickson.pm - Cayley-Dickson constructions and algebriac manipulations
#
#   author: Jeffrey B Anderson - truejeffanderson at gmail.com
#
#     reference: https://en.wikipedia.org/wiki/Cayley-Dickson_construction
#

package CayleyDickson;
use Data::Dumper;
use strict;
no  warnings;
use overload qw(- subtract + add * multiply / divide "" as_string eq eq);
use constant SYMBOLS   => ['', 'i' .. 'z', map('a'.$_,('a' .. 'z')),(map('b'.$_,('a' .. 'z'))) x 100];


sub eq { shift->as_string eq shift }

# Gamma: algebra selection: -1=cayley-dickson, 0=dual complex, 1=split complex
sub gamma { -1 }

# Conjugate: z* = (a,b)* = (-a,b*)
sub conjugate {
   my $m = shift;
   my $a = ref $m->a ? $m->a->conjugate : $m->a;
   my $b = -$m->b;
   (ref $m)->new($a,$b)
}

# Invert: 1/z = z⁻¹ = (a,b)⁻¹ = (a,b)*/(norm(a,b)²)
sub inverse {
   my $m  = shift;
   my $c = $m->conjugate;
   my $n = $m->norm;
   $c / ($n ** 2)
}

# Norm: z->norm = √(norm(a)²+norm(b)²) and norm(number) = number
sub norm {
   my $m = shift;
   my $a = ref $m->a ? $m->a->norm : $m->a;
   my $b = ref $m->b ? $m->b->norm : $m->b;
   sqrt($a ** 2 + $b ** 2)
}

# Addition: z1+z2 = (a,b)+(c,d) = (a+c,b+d)
sub add {
   my ($m,$o) = @_;
   my $a = $m->a;
   my $b = $m->b;
   my $c = $o->a;
   my $d = $o->b;
   (ref $m)->new($a+$c, $b+$d)
}

# Subtraction: (a,b)-(c,d) = (a-c,b-d)
sub subtract {
   my ($m,$o,$s) = @_;
   $o = (ref $m)->new((my $v = $o), 0);
   my $a = $s ? $o->a : $m->a;
   my $b = $s ? $o->b : $m->b;
   my $c = $s ? $m->a : $o->a;
   my $d = $s ? $m->b : $o->b;
   (ref $m)->new($a-$c, $b-$d)
}

# Divide: z1/z2 = (a,b) × (c,d)⁻¹ = (a,b) × inverse(c,d)
sub divide {
   my ($m,$o,$s) = @_;
   my $a = $s ? $m->inverse : $m;
   my $b = $s ? $o : (ref $o ? $o->inverse : 1/$o);
   $a * $b
}

# Multiply: (a,b)×(c,d) = (a×c - d*×b, d×a + b×c*) where x* = conjugate(x) or x if x is a number.
sub multiply {
   my ($m,$o,$s) = @_;
   return $m * $o if $s;
   my $g = $m->gamma;
   my ($a,$b,$c,$cs,$d,$ds);
   $a = $m->a;
   $b = $m->b;
   if (ref $o) {
      $c  = $o->a;
      $d  = $o->b;
      $cs = ref $o->a ? $o->a->conjugate :$o->a;
      $ds = ref $o->b ? $o->b->conjugate :$o->b
   }
   else {
      $c = $cs = $o;
      $d = $ds = 0
   }
   (ref $m)->new($a*$c + $g*$ds*$b, $d*$a + $b*$cs)
}

# Tensor: A⊗ B = (a,b)⊗ (c,d) = (ac,ad,bc,bd)
sub tensor {
   my ($m,$o) = @_;
   my $a = ref $o->a ? tensor($m,$o->a) : $m * $o->a;
   my $b = ref $o->b ? tensor($m,$o->b) : $m * $o->b;
   (ref $o or ref $m)->new($a, $b)
}


################################################
# Creates a new CayleyDickson object.
# input should be 2 numbers (or a list of 2^n numbers)
sub new { 
   my $c = shift;
   my $n = scalar @_;
   my @pair = $n > 2 ? (\\\($c->new(@_[0 ..$n/2-1])),\\\($c->new(@_[$n/2 ..$n-1]))) : ((ref $_[0] and ref $_[0] ne $c) ? (@_) : (\\\$_[0],\\\$_[1]));
   bless [@pair] => $c
}

# object dumping tool ...
sub d {
   my %a = @_;
   my @k = keys %a;
   my $d = Data::Dumper->new([@a{@k}],[@k]); $d->Purity(1)->Deepcopy(1); print $d->Dump;
}


# a holds the left object and b holds the right one.
# if these are numbers, then this object represents the complex number of a+bi.
sub a { $$${(shift)->[0]} }
sub b { $$${(shift)->[1]} }

# flatten object ends into arrays for easy manipulations ...
sub flat {
   my $m = shift;
   ref $m->a ? ($m->a->flat, $m->b->flat) : ($m->a, $m->b)
}

sub tips {
   my $m = shift;
   ref $m->a ? (tips($m->a),tips($m->b)) : (@$m);
}


# print the beautiful objects in terse human format ...
sub as_string {
   my ($m,$i,$s) = (shift,0,'');
   foreach my $t ($m->flat) {
      if ($t or not $i) {
        $s .= sprintf '%s%s%s', ($t < 0 ? '-' : '+'), abs($t), ${SYMBOLS()}[$i]
      }
      $i++
   }
   $s
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

