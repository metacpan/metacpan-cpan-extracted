#
# Tangle.pm - A quantum state machine
#
#     reference: https://youtu.be/F_Riqjdh2oM
#


package Tangle;
use base qw(CayleyDickson);
use utf8;
use strict;
use constant HR => sqrt(1/2);
use constant LONG_NAMES => 0;
our $VERSION = 0.03;


#
# CNOT: A⊗ B = (a,b)⊗ (c,d) = (ac,ad,bc,bd)
#
sub cnot {
   my ( $control, $target ) = @_;

   my $tensor = $control->tensor($target);

   my $q1 = HR * Tangle->new(1,1,1,1);
   my $cnot = 1 / $q1 * $tensor * $q1;

   $target->_extend;
   my @cf = $cnot->flat;
   $target->_gate(Tangle->new(@cf[0,1,3,2]));
   my @tt = $target->tips;

   my @ct;
   _extend($control) while (@ct = $control->tips) < @tt;

   #$control->_gate(Tangle->new(@tt[0,2,3,1]));
   ${$ct[0]} = ${$tt[0]};
   ${$ct[1]} = ${$tt[2]};
   ${$ct[2]} = ${$tt[3]};
   ${$ct[3]} = ${$tt[1]};
   $target
}


# 
# swap: (a,b) => (b,a)
#
# TODO: Change this into a gate. I think
#
sub swap {
   my $m = shift;

   # swap target ends...
   my $a   = $m->[0];
   my $b   = $m->[1];
   $m->[1] = $a;
   $m->[0] = $b;
   $m
}



# 
# _extend: replace the ends containing numbers with new objects containing two numbers
# this effectively doubles the dimensions of your Cayley Dickson number
#
sub _extend {
   my $m = shift;

   if ($m->is_qbit) {
      $${$m->[0]} = \((ref $m)->new((my $u = $m->a), 0));
      $${$m->[1]} = \((ref $m)->new((my $u = $m->b), 0));
   }
   else {
      _extend($m->a);
      _extend($m->b);
   }
   $m
} 



#
# gate functions ...
#
sub x     { my $m = shift; $m->_gate(     (ref $m)->new(  0,  1 ) / $m) }
sub y     { my $m = shift; $m->_gate(     (ref $m)->new(  0, -1 ) / $m) }
sub z     { my $m = shift; $m->_gate(     (ref $m)->new( -1,  0 ) / $m) }
sub i     { my $m = shift; $m->_gate(     (ref $m)->new(  1,  0 ) / $m) }
sub h     { my $m = shift; $m->_gate(HR * (ref $m)->new(  1,  1 ) / $m) }
sub xx    { die 'incomplete function placeholder' }
sub yy    { die 'incomplete function placeholder' }
sub zz    { die 'incomplete function placeholder' }
sub u     { die 'incomplete function placeholder' }
sub d     { die 'incomplete function placeholder' }
sub cx    { die 'incomplete function placeholder' }
sub cy    { die 'incomplete function placeholder' }
sub cz    { die 'incomplete function placeholder' }
sub cs    { die 'incomplete function placeholder' }
sub not   { die 'incomplete function placeholder' }
sub rswap { die 'incomplete function placeholder' }
sub rnot  { die 'incomplete function placeholder' }
sub ccnot { die 'incomplete function placeholder' }

# DONT USE THE method name "shift" !!!
#sub shift { die 'incomplete function placeholder' }


#
# optional long form function naming ..,
#
sub phase_shift { shift->shift(@_) }
sub detsch      { shift->d(@_)     }
sub hadamard    { shift->h(@_)     }
sub i_gate      { shift->i(@_)     }
sub pauli_i     { shift->i(@_)     }
sub identity    { shift->i(@_)     }
sub universal   { shift->u(@_)     }
sub x_gate      { shift->x(@_)     }
sub pauli_x     { shift->x(@_)     }
sub y_gate      { shift->y(@_)     }
sub pauli_y     { shift->y(@_)     }
sub z_gate      { shift->z(@_)     }
sub pauli_z     { shift->z(@_)     }
sub cswap       { shift->cs(@_)    }
sub fredkin     { shift->cs(@_)    }
sub xnot        { shift->cx(@_)    }
sub ynot        { shift->cy(@_)    }
sub znot        { shift->cz(@_)    }
sub ising_xx    { shift->xx(@_)    }
sub ising_yy    { shift->yy(@_)    }
sub ising_zz    { shift->zz(@_)    }
sub root_not    { shift->rnot(@_)  }
sub root_swap   { shift->rswap(@_) }
sub toffoli     { shift->ccnot(@_) }
# end long form function naming


#
# create a new object
# expects 2 (or 2^n) parameters of numbers of objects
#
sub new {
   my $c        = shift;
   my @values   = @_;
   my $elements = scalar @values;
   my ($a, $b);
   if ($elements > 2) {
      $a = $c->new(@values[ 0           .. $elements/2 - 1 ]);
      $b = $c->new(@values[ $elements/2 .. $elements   - 1 ]);
   }
   else {
      $a = $values[0];
      $b = $values[1];
   }
   bless [ \\\$a, \\\$b ] => $c
}



#
# hold the left number/object in a and the right number/object in b.
#
sub a { $$${ (shift)->[0] } }
sub b { $$${ (shift)->[1] } }



#
# is_qbit: a conceptual renaming of the method is_complex()
#
sub is_qbit { shift->is_complex }



#
# flatten object ends into arrays for easy manipulations ...
#
sub flat {
   my $m = shift;

   $m->is_qbit ? $m->a : $m->a->flat, 
   $m->is_qbit ? $m->b : $m->b->flat 
}



#
# return ordered coefficients as an array ...
#
sub tips {
   my $m = shift;

   $m->is_qbit ? @$m : ( $m->a->tips, $m->b->tips )
}



# 
# _gate: copy the content from @to to @tm ...
#
sub _gate {
   my ( $m, $o ) = @_;

   my @origin  = $m->tips;
   my @replace = $o->tips;

   foreach my $i (0 .. $#replace) {
      $${ $origin[$i] } = \($$${ $replace[$i] })
   }
   $m
}



# 
# state: actual probability states being the quadrance or the square of the magnitude of the values ...
#
sub state {
   my $m = shift;

   [
      ( $m->is_qbit ? abs $m->a ** 2 : @{ $m->a->state } ),
      ( $m->is_qbit ? abs $m->b ** 2 : @{ $m->b->state } )
   ]
}



# 
# raw_state: state as an array reference ...
#
sub raw_state {
   my $m = shift;

   [
      ( $m->is_qbit ? $m->a : @{ $m->a->raw_state } ),
      ( $m->is_qbit ? $m->b : @{ $m->b->raw_state } )
   ]
}



# 
# measure: a singular measure ...
#
sub measure {
   my $m = shift;

   my $s = $m->state;
   my $n = 0;
   my $r = rand 1;
   foreach my $p (@$s) {
      $r -= $p;
      last if $r < 0;
      $n ++
   }
   $n
}



# 
# measures: a repeated collection of measures for a specified number of runs
# returns a hash reference: { measured_value => count_of_runs_matching_this_value, ...}
#
sub measures {
   my ( $my, $count ) = @_;
   $count ||= 1;

   my %list;
   foreach (1 .. $count) {
      my $measure = $my->measure;
      $list{ $measure } ||= 0;
      $list{ $measure } ++
   }

   foreach my $key (keys %list) {
      $list{ $key } = $list{ $key } / $count
   }
   \%list
}

=encoding utf8

=pod

=head1 NAME

Tangle - a quantum state machine

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

 Create quantum probability states in classic memory.
 Preform quantum gate manipulations and measure the results.
 Ideal for testing, simulating and understanding quantum programming concepts.

=back

=head1 USAGE


=head2 new()

=over 3

 # create a new Tangle object in the |0> state ...
 my $q1 = Tangle->new(0,1);

=back

=head2 cnot()

=over 3

 # tensors this object onto the given one and flip the second half accordingly ...
 my $q2 = Tangle->new(0,1);

 # q1 ⊗ q2
 $q2->cnot($q1);

 # both $q and $q2 are now sharing memory so that changes to one will effect the other.

=back

=head2 *_gate()

=over 3

 * functioning gates are x, y, z, i and sometimes cnot.
 
 # unitary gate functions ...
 
 $q->x; # x-gate
 $q->y; # y-gate
 $q->z; # z-gate
 $q->i; # identity

 # partially operational gates ...
 
 $q->cnot;
 $q->swap;

 # other common gates ...
 # context: https://en.wikipedia.org/wiki/Quantum_logic_gate 
 
 $q->h;     # hadamard
 $q->xx;    # isling (xx) coupling gate
 $q->yy;    # isling (yy) coupling gate
 $q->zz;    # isling (zz) coupling gate
 $q->u;     # universal gate... quantum cheating
 $q->d;     # deutsch gate ... not in the real world yet.
 $q->cx;    # controlled x-not = cnot() gate
 $q->cy;    # controlled y-not
 $q->cz;    # controlled z-not
 $q->cs;    # controlled swap gate 
 $q->rswap; # root swap
 $q->rnot;  # root not
 $q->ccnot; # toffoli gate

=back

=head2 state()

=over 3

 # square of the coefficients of this number.
 # or ... the probability states as percentages for each outcome (seeing a 1 in that location if you looked).
 
 my $i = 0;
 print "chance of outcome:\n";
 foreach my $percent (@{$q->state}) {
    $i++;
    print "$i: $percent%%\n";
 }

=back

=head2 raw_state()

=over 3

 # state of raw amplitudes as an array reference ...
 printf "The coefficients of q: [%s]\n", join(', ', @{$q->state};

=back

=head2 measure()

=over 3

 # a singular measure based on the current probability state.
 printf "The answer is: %s\n", $q->measure

=back

=head2 measures()

=over 3

 # a set of singular measures returned as a hash
 # the keys match the actual measurements found
 # and the values of those keys is the number of times that measure was found in the set
 # first parameter is the number of measures you want to preform ...
 
 foreach my $measured ( keys %{$q->measures(1000)} ) {
    printf "Measured '%d': %d times\n", $measured, $q->{measures}->{ $measured };
 }

=back

=head1 SUMMARY

=over 3

 The goal of this project is to provide a minimal universal quantum emulator for coders.

 Conceptually, things are numbers or objects. Every objects contains two numbers or two objects. 

 If an object contains two numbers it must be complex. If an object contains four numbers it must contain two more objects where each sub-object contains 2 numbers, so that your original number has 4 numbers deeper within it. If an object contains more numbers it must contain more depth and pairs of objects contain pair of objects and so on and so on.

 Objects of any size can add, multiply, subtract and divide with one another.

 Objects can be tensored which is similar to storing the products of associative multiplication without completing the summation.
  ie: real number multiplication: (a+b) × (c+d) = ac + ad + bc + bd
                  tensor product: (a,b) ⊗ (c,d) = ac,  ad,  bc,  bd

 A gate is a rotational transformation. Rotation transformations are represented by invertible matrix which are there own inverse and can be represented by a Cayley Dickson number.

 Objects contain Cayley Dickson number representations, so gates are Tangle objects as well.

 Using a gate with 2 or more inputs will put your state into superposition, so that we can not gleen the individual qbit states from the given probability distribution.


 Output from binary gates will be objects with 4 numbers, which are attached to the output in a manner which represents lesser and greater binary control over its future changes.

 We cannot determine the individual states of the input qbits to set them after the gate transformation, we need to attach the input qbits to the gate output so that they each share the same output in different ways.

 Quantum gates are laid out in series, one after the other. Shared memory from the output of one gate needs to be maintained when an entangled qbit is subsequently put through another gate. This is done by taking the partial products of the gate and its inputs and then stitching that output back to the ends of the existing input ends.

 A qbit and its gate have no way of knowing whether another variable is sharing its memory, there is no way to update the one without destroying the connection to the other. Since the existing ends could be shared already with existing entangled qbits, the connection between an objects and number needs to be expanded. In this code we preform this by having 3 pointer references between each object and number. This allows two entangled variables to remain entanglment after one of them is put through a gate and its value is changed accordingly.

 An object is an array containing a pair triple references to either another object or to a number. This represents a Cayley Dickson number which is used to represent the probability state of a quantum computer. The square of the coefficient (number) in each dimension of this object is the probability of seeing a 1 there if you measured in that state. The probabilities of a quantum computer can be thought of as rotations in high dimensions. Cayley Disckson numbers rotate in high dimension by multiplying together.

 Quantum gates can be represented by static Cayley Dickson numbers and multiplied by existing states in order to produce outputs. In other words, the object used to store your quantum probability state is the same object used to represent quantum gates. ie: this object. Binary quantum gates produce unreduced outputs that are stitched back onto the ends of the inputs with links that share those numbers in different orders. There is seperation between objects and numbers so a number be split into two numbers and all other qbits previously sharing the original number will also automatically share the two new numbers as well.
 

 # Sample quantum program:
 #
 # This simple example will result in a measurement of |00> or |11> showing entanglement
 # where the measure of one qbit will always equal the second.

 my $q1 = Tangle->new(1,0);
 my $q2 = Tangle->new(1,0);
 $q1->hadamard;
 $q1->tensor($q2);
 printf "measured: %d\n", $q2->measure;

=back

=head1 AUTHOR

 Jeff Anderson
 truejeffanderson@gmail.com

=cut


1;

__END__

