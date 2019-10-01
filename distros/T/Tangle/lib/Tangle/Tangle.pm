#
# Tangle.pm - A quantum state machine
#
#   author: Jeffrey B Anderson - truejeffanderson at gmail.com
#
#     reference: https://youtu.be/F_Riqjdh2oM
#

package Tangle;
use base qw(CayleyDickson);
use strict;
use constant HALF_ROOT => sqrt(1/2);

# Tensor: A⊗ B = (a,b)⊗ (c,d) = (ac,ad,bc,bd)
sub cnot {
   my ($control,$target) = @_;
   my @tt = $target->tips;
   my @ct = $control->tips;

   # generate the tensor products ...
   my @tp = $target->tensor($control)->tips;

   #_extend($control) while $control->flat < @tt;
   while (@ct < @tt) {
      _extend($control);
      @ct = $control->tips;
   }

   # attach the results to target and control lines ...
   my $nc = scalar @ct;
   foreach my $i (0 .. scalar @ct - 1) {
      $${$ct[$i]} = \((ref $control )->new($tp[$i],$tp[$nc + $i]));
      $${$tt[$i]} = \((ref $control )->new($tp[2*$i],$tp[2*$i+1]));
   }
   # flip the b lines on target ...
   $target->b->swap;
   $target;
}

sub swap {
   my $m = shift;
   # swap target ends...
   my $a = ${$m->[0]};
   my $b = ${$m->[1]};
   ${$m->[1]} = $a;
   ${$m->[0]} = $b;
}

# operates directly on input to extend the tips. existing tip values are destroyed ...
sub _extend {
   my $m = shift;
   foreach my $t ($m->tips) {
      $$$t = \((ref $m)->new(0,0));
   }
} 

# single x,y,z,i gates ...
sub x_gate   { my $m = shift; my @mf = $m->flat; $m->_gate((ref $m)->new( 0, 1,((0) x (@mf-2))) / $m) }
sub y_gate   { my $m = shift; my @mf = $m->flat; $m->_gate((ref $m)->new( 0,-1,((0) x (@mf-2))) / $m) }
sub z_gate   { my $m = shift; my @mf = $m->flat; $m->_gate((ref $m)->new(-1, 0,((0) x (@mf-2))) / $m) }
sub i_gate   { my $m = shift; my @mf = $m->flat; $m->_gate((ref $m)->new( 1, 0,((0) x (@mf-2))) / $m) }

# dual gates ...
sub hadamard { my $m = shift; $m->_gate($m->norm ** 2 * (ref $m)->new(HALF_ROOT, HALF_ROOT ) / $m)  }

# triple gates and beyond ...

# a list of common qbit manipulation *_gates...
sub _gate {
   my $m = shift;
   my $o = shift;
   my @mo = $m->tips;
   my @to = $o->tips;
   foreach my $i (0 .. $#to) {
      $${$mo[$i]} = $${$to[$i]};
   }
   $m;
}

# raw state as an arrary reference ...
sub raw_state {
   my $my = shift;
   my $ma = [(ref $my->a and $my->a->can('raw_state')) ? @{$my->a->raw_state} : $my->a];
   my $mb = [(ref $my->b and $my->b->can('raw_state')) ? @{$my->b->raw_state} : $my->b];
   [@$ma, @$mb];
}

sub state {
   my $my = shift;
   my $ma = [(ref $my->a and $my->a->can('state')) ? @{$my->a->state} : abs($my->a) ** 2];
   my $mb = [(ref $my->b and $my->b->can('state')) ? @{$my->b->state} : abs($my->b) ** 2];
   [@$ma, @$mb];
}

# a singular measure ...
sub measure {
   my $my    = shift;
   my $state = $my->state;
   my $rand  = rand 1;
   my $unit = 0;
   foreach my $prob (@$state) {
      $rand -= $prob;
      last if $rand < 0;
      $unit++;
   }
   $unit;
}

# a repeated collection of measures for a specified number of runs
# returned as a list of { measured_value => count_of_runs_matching_this_value, ...}
# NOTE: there is a way to do this that splits the probabilities down the chain from the top. It will be quicker ...
sub measures {
   my $my = shift;
   my $count = shift || 1;
   my %list;
   foreach (1 .. $count) {
      my $measure = $my->measure;
      $list{$measure} ||= 0;
      $list{$measure}++;
   }
   foreach my $key (keys %list) {
      $list{$key} = $list{$key} / $count;
   }
   return \%list;
}

1;

__END__

