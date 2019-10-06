#
# Tangle.pm - A quantum state machine
#
#   author: Jeffrey B Anderson - truejeffanderson at gmail.com
#
#     reference: https://youtu.be/F_Riqjdh2oM
#


package Tangle;
use base qw(CayleyDickson);
use utf8;
use strict;



#
# Tensor: A⊗ B = (a,b)⊗ (c,d) = (ac,ad,bc,bd)
#
sub cnot {
   my ( $control,$target ) = @_;

   my $tensor = $control->tensor($target);

   my $q1 = Tangle->new( sqrt(1/2), sqrt(1/2), sqrt(1/2), sqrt(1/2) );
   my $cnot = 1/$q1 * $tensor * $q1;

   $target->_extend;
   my @cf = $cnot->flat;
   $target->_gate(Tangle->new(@cf[0,1,3,2]));
   my @tt = $target->tips;

   my @ct;
   _extend($control) while (@ct = $control->tips) < @tt;

   #
   # HELP: this is where I am having trouble. I think...
   #
   #$control->_gate(Tangle->new(@tt[0,2,3,1]));
   ${$ct[0]} = ${$tt[0]};
   ${$ct[1]} = ${$tt[2]};
   ${$ct[2]} = ${$tt[3]};
   ${$ct[3]} = ${$tt[1]};

   return $cnot; # target
}


# 
# swap: (a,b) => (b,a)
#
sub swap {
   my $m = shift;
   my ( $a, $b );

   # swap target ends...
   $a      = $m->[0];
   $b      = $m->[1];
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

   ref $m->a ? _extend($m->a) : ( $${$m->[0]} = \((ref $m)->new((my $u = $m->a), 0)) );
   ref $m->b ? _extend($m->b) : ( $${$m->[1]} = \((ref $m)->new((my $v = $m->b), 0)) );
   $m
} 



sub x_gate   { my $m = shift; my @mf = $m->flat; $m->_gate((ref $m)->new( 0, 1) / $m) }
sub y_gate   { my $m = shift; my @mf = $m->flat; $m->_gate((ref $m)->new( 0,-1) / $m) }
sub z_gate   { my $m = shift; my @mf = $m->flat; $m->_gate((ref $m)->new(-1, 0) / $m) }
sub i_gate   { my $m = shift; my @mf = $m->flat; $m->_gate((ref $m)->new( 1, 0) / $m) }

sub hadamard {
   my $m = shift;

   my $q1 = Tangle->new( sqrt(1/2), sqrt(1/2) );
   my $v = $q1 * 1/$m;
   $m->_gate($v)
}



sub new {
   my ( $c, $n ) = ( shift, scalar @_ );

   my @pair;
   if ($n > 2) {
      @pair = ( \\\($c->new(@_[0 .. $n/2-1])), \\\($c->new(@_[$n/2 .. $n-1])) )
   }
   elsif (ref $_[0] and ref $_[0] ne $c) {
      @pair = @_
   }
   else {
      @pair = (\\\$_[0], \\\$_[1])
   }
   bless [@pair] => $c
}



#
# hold the left number/object in a and the right number/object in b.
#
sub a { $$${ (shift)->[0] } }
sub b { $$${ (shift)->[1] } }



# flatten object ends into arrays for easy manipulations ...
sub flat {
   my $m = shift;

   ref $m->a ? flat($m->a) : $m->a, 
   ref $m->b ? flat($m->b) : $m->b
}



sub tips {
   my $m = shift;

   ref $m->a ? (tips($m->a),tips($m->b)) : (@$m)
}



# 
# _gate: copy the content from @to to @tm ...
#
sub _gate {
   my ( $m, $o, @tm, @to ) = @_;

   @tm = $m->tips;
   @to = $o->tips;

   foreach my $i (0 .. $#to) {
      $${ $tm[$i] } = \($$${ $to[$i] })
   }

   $m
}



# 
# state: actual probability states being the quadrance or the square of the magnitude of the values ...
#
sub state {
   my $m = shift;

   [
      ( (ref $m->a and $m->a->can('state')) ? @{ $m->a->state } : abs ($m->a) ** 2 ),
      ( (ref $m->b and $m->b->can('state')) ? @{ $m->b->state } : abs ($m->b) ** 2 )
   ]
}



# 
# raw_state: state as an array reference ...
#
sub raw_state {
   my $m = shift;

   [
      ( (ref $m->a and $m->a->can('raw_state')) ? @{ $m->a->raw_state } : $m->a ),
      ( (ref $m->b and $m->b->can('raw_state')) ? @{ $m->b->raw_state } : $m->b )
   ]
}



# 
# measure: a singular measure ...
#
sub measure {
   my ( $s, $n, $r ) = ( (shift)->state, 0, rand 1 );

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
   my ( $my, $count, %list) = ( shift, shift || 1 );

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

 create Cayley-Dickson constructed numbers and perform math operations on them.
 also creates tensor products.

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

=head2 x_gate()

=over 3

 something

=back

=head2 y_gate()

=over 3

 something

=back

=head2 z_gate()

=over 3

 something

=back

=head2 state()

=over 3

 something

=back

=head2 raw_state()

=over 3

 something

=back

=head2 measure()

=over 3

 something

=back

=head2 measures()

=over 3

 something

=back

=head1 SUMMARY

=over 3

 create Cayley-Dickson constructions

=back

=head1 AUTHOR

 Jeffrey B Anderson
 truejeffanderson@gmail.com

=cut


1;

__END__

