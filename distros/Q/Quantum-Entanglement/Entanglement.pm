package Quantum::Entanglement;
use strict;
use warnings;
use Carp;

BEGIN {
  use Exporter   ();
  use Math::Complex;
  my @M_Complex = qw(i Re Im rho theta arg cplx cplxe);
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
  $VERSION     = 0.32;
  @ISA         = qw(Exporter);
  @EXPORT      = qw(&entangle &p_op &p_func &q_logic
		    &save_state &restore_state);
  %EXPORT_TAGS = (DEFAULT => [@EXPORT],
		  complex => [@M_Complex],
		  QFT => [qw(&QFT)],);
  @EXPORT_OK   = (@M_Complex, '&QFT');
}
our (@EXPORT_OK, @EXPORT);

$Quantum::Entanglement::destroy = 1; # true=> p(0) states stomped on
$Quantum::Entanglement::conform = 0; # true=> strives for truth when observing

## Contents:
# Constructors
# Utility Routines
# Overload table
# Overload routines
# parallel operators and functions
# methods for saving and restoring state
# pod

# =begin pretty pictures
#
# Things look a bit like this...
#
# $variable = [ref to var which itself refs to an annon array (the universe),
#	       offset of values of variable within universe,
#	       ref to var which itself refs to an annon array (the offsets)];
#
# $offsets =  [refs to all the offsets in a given universe, ...]
# $universe=  [ [prob1,val1,prob2,val2],
#	        [prob1,val1,prob2,val2], etc. ]
#
# =cut

# creates a new set of universes
sub _new {
  my $universe = [];
  my $offsets = [];
  my $var = [\$universe,1,\$offsets];
  $offsets->[0] = \ $var->[1];
  while (@_) {
    push @$universe, [shift,shift];
  }
  bless $var, 'Quantum::Entanglement';
  return $var;
}

# add a variable without adding values (ie. a derived value)
# returns the new variable
sub _add {
  my $current = $_[0];
  my $universe = ${ $current->[0]};
  my $offset = scalar(@{$universe->[0]}) + 1;
  my $var= [\$universe,$offset,\ ${$current->[2]}];
  push @{${$current->[2]}} , \$var->[1];
  bless $var, 'Quantum::Entanglement';
  return $var;
}

# joins together two previously unconnected universes
# takes two variables as args, gets the universes from those.
# should be used to modify objects in place.
sub _join {
  my ($uni1,$uni2) = (${$_[0]->[0]},${$_[1]->[0]});
  return () if $uni1 == $uni2;
  my $universe = [];
  foreach my $s2 (@$uni2) {
    foreach my $s1 (@$uni1) {
      push @$universe, [@$s1,@$s2];
    }
  }
  my $offsets1 = ${$_[0]->[2]};
  my $offsets2 = ${$_[1]->[2]};
  my $extra = scalar(@{$uni1->[0]});
  push @$offsets1, map {$$_+=$extra; $_} @$offsets2;
  ${$_[1]->[2]} = $offsets1;
  ${$_[0]->[0]} = $universe;
  ${$_[1]->[0]} = $universe;
  return (1);
}

# exported constructor
sub entangle {
  return _new(@_);
}

## Utility routines

# a view of global state space, might still show historical states which
# are no longer accessable, does not count as observation
sub show_states {
  my $rt;
  my $var = shift;
  my $universe = ${$var->[0]};
  if ($_[0]) {
    foreach (@$universe) { my $t;
      $rt .= (++$t % 2) ? "$_|" : overload::StrVal($_).">\t" foreach @$_;
      $rt .= "\n";
    }
  }
  else {
    my $os = $var->[1];
    $rt .= $_->[$os-1]."|".overload::StrVal($_->[$os]).">\t"
      foreach @$universe;
    substr($rt,-1,1,"\n");
  }
  return $rt;
}

# egads! (and don't tell anyone about the grep, it's a secret)
sub DESTROY {
  my ($universe, $offsets) = (${$_[0]->[0]}, ${$_[0]->[2]});
  my $os = $_[0]->[1];
  splice(@$_,$os-1,2) foreach @$universe;
  @$offsets = grep {if ($$_ != $os) {$$_ -= 2 if $$_ > $os;1;} else {0;}}
               @$offsets;
  _rationalise_states([\$universe])
          if $Quantum::Entanglement::destroy;
}

# takes two non normalised probabilities and returns true with prob(1/1+2)
sub _sel_output {
  my ($c, $d) = @_;
  $c = abs($c)**2;
  $d = abs($d)**2;
  return rand(1) < ($c/($c+$d)) ? 1 : 0;
}

# Gets a ref to a hash of complex probs, produces ref to hash of sequential
# probs and ref to array of ordering.
sub _normalise {
  my $hr = $_[0];
  my $h2 = {};
  my $muts = [keys %{$hr}];
  my $sum = 0;
  foreach (values %{$hr}) {
    $sum += abs($_)**2;
  }
  if ($sum <= 0) {
    croak "$0: Cannot behave probabilistically with -ve probs";
  }
  else {
    my $cum;
    @{$h2}{ @{$muts} } = map {$cum +=abs($_)**2;
			      $cum / $sum       } @{$hr}{ @{$muts} };
    return ($h2, $muts);
  }
}

# this builds up a multi-layered hash so as to find the unique sets of
# states, it then uses _unravel to get them back out of the hash
sub _rationalise_states {
  my $universe = ${$_[0]->[0]};
  my $len = scalar(@{$universe->[0]})/2;
  my @p_os = map {$_*2  } (0..$len-1);
  my @v_os = map {$_*2+1} (0..$len-1);
  my $foo = {};
  foreach my $state (@$universe) { # build an icky data structure
    my $tref = $foo;
    foreach (@v_os) {
      my $val = ref($state->[$_]) ? overload::StrVal($state->[$_])
	                          : $state->[$_];
      if ($_==2*$len-1) { # last level of the structure
	if (exists $tref->{$val}) {
	  my @temp = @{$state}[@p_os];
	  $_+=shift @temp foreach @{$tref->{$val}}[@p_os];
	}
	else {
	  $tref->{$val} = [@{$state}];
	}
      }
      else { # an intermediate level
	if (exists $tref->{$val}) {
	  $tref = $tref->{$val};
	}
	else {
	  $tref = $tref->{$val} = {};
	}
      }
    }
  }
  # do something with it...
  @$universe =();
  while (1) {
    my $aref = _unravel($foo);
    last unless $aref;
    push @$universe, $aref;
  }
  return $universe;
}

sub _unravel {
  my $tref = $_[0];
  return undef unless (scalar keys %$tref);
  my @hrs;
  my($last_ref, $val);
  do {
    $last_ref = $tref;
    ($val,$tref) = %$tref;
    unshift @hrs, $val, $last_ref;
  } until (ref($tref) eq 'ARRAY');
  delete ${$last_ref}{$val};
  splice @hrs, 0,2;
  while (@hrs) {
    my $val = shift @hrs;
    my $h = shift @hrs;
    delete ${$h}{$val} if scalar(keys %{${$h}{$val}}) < 1;
  }
  return $tref;
}


##
# Overloading.  Everything except for assignment operators
# are overloaded specifically.  Need to specifically overload a lot
# of stuff so that pruning of states can happen as soon as poss

use overload
  '+'  => sub { binop(@_, sub{$_[0] + $_[1]} ) },
  '*'  => sub { binop(@_, sub{$_[0] * $_[1]} ) },
  '-'  => sub { binop(@_, sub{$_[0] - $_[1]} ) },
  '/'  => sub { binop(@_, sub{$_[0] / $_[1]} ) },
  '**' => sub { binop(@_, sub{$_[0] **$_[1]} ) },
  '%'  => sub { binop(@_, sub{$_[0] % $_[1]} ) },
  'x'  => sub { binop(@_, sub{$_[0] x $_[1]} ) },
  '.'  => sub { binop(@_, sub{$_[0] . $_[1]} ) },
  '<<' => sub { binop(@_, sub{$_[0] <<$_[1]} ) },
  '>>' => sub { binop(@_, sub{$_[0] >>$_[1]} ) },
  '&'  => sub { binop(@_, sub{$_[0] & $_[1]} ) },
  '|'  => sub { binop(@_, sub{$_[0] | $_[1]} ) },
  '^'  => sub { binop(@_, sub{$_[0] ^ $_[1]} ) },
  '~'  => sub { unnop($_[0], sub { ~$_[0]} ) },
  'neg'=> sub { unnop($_[0], sub { -$_[0]} ) },
  '!'  => sub { unnop($_[0], sub { !$_[0]} ) },
  '++' => sub { mutop($_[0], sub {++$_[0]} ) },
  '--' => sub { mutop($_[0], sub {--$_[0]} ) },
  '<'  => sub { bioop(@_, sub{$_[0] <  $_[1]} ) },
  '>'  => sub { bioop(@_, sub{$_[0] >  $_[1]} ) },
  '<=' => sub { bioop(@_, sub{$_[0] <= $_[1]} ) },
  '>=' => sub { bioop(@_, sub{$_[0] >= $_[1]} ) },
  '==' => sub { bioop(@_, sub{$_[0] == $_[1]} ) },
  '!=' => sub { bioop(@_, sub{$_[0] != $_[1]} ) },
  'lt' => sub { bioop(@_, sub{$_[0] lt $_[1]} ) },
  'le' => sub { bioop(@_, sub{$_[0] le $_[1]} ) },
  'ge' => sub { bioop(@_, sub{$_[0] ge $_[1]} ) },
  'gt' => sub { bioop(@_, sub{$_[0] gt $_[1]} ) },
  'eq' => sub { bioop(@_, sub{$_[0] eq $_[1]} ) },
  'ne' => sub { bioop(@_, sub{$_[0] ne $_[1]} ) },
  '<=>'=> sub { binop(@_, sub{$_[0] <=>$_[1]} ) },
  'cmp'=> sub { binop(@_, sub{$_[0] cmp$_[1]} ) },
  'cos'=> sub { unnop($_[0], sub{ cos $_[0]} ) },
  'sin'=> sub { unnop($_[0], sub{ sin $_[0]} ) },
  'exp'=> sub { unnop($_[0], sub{ exp $_[0]} ) },
  'abs'=> sub { unnop($_[0], sub{ abs $_[0]} ) },
  'log'=> sub { unnop($_[0], sub{ log $_[0]} ) },
  'sqrt'=>sub { unnop($_[0], sub{ sqrt $_[0]}) },
  'atan2'=>sub{ binop(@_, sub{atan2($_[0], $_[1])} ) },
  '&{}'=> \&sub_ent,
  'bool'=> \&bool_ent, q{""}  => \&str_ent,  '0+' => \&num_ent,
  '='   => \&copy_ent,
  'fallback' => 1;

# copying (not observation, clones states, does not increase state space)
sub copy_ent {
  my $os = $_[0]->[1];
  my $val = $_[0]->_add;
  my $universe = ${$_[0]->[0]};
  push(@$_, $_->[$os-1], $_->[$os]) foreach @$universe;
  return $val;
}

# running entangled subroutines
sub sub_ent {
  my $obj = $_[0];
  my $os = $obj->[1];
  my $universe = ${$obj->[0]};
  return sub {
    my $var = $obj->_add;
    foreach my $state (@$universe) {
      push(@$state, $state->[$os-1],
	   scalar( $state->[$os]->(@_) ));
    }
    return $var;
  }
}

# stringification (observation)
sub str_ent {
  my $c = $_[0];
  my $os = $c->[1];
  my $universe = ${$c->[0]};
  my %str_vals;
  # work out which state we want to retain
  foreach my $state (@$universe) {
    $str_vals{$state->[$os]} = $state->[$os-1] + ($str_vals{$state->[$os]}||0);
  }

  my ($hr, $ar) = _normalise(\%str_vals);
  my $rand = rand(1);
  my $rt;
 LOOP: foreach (@$ar) {
    if ( $rand < ${$hr}{$_}) {
      $rt = $_;
      last LOOP;
    }
  }
  # retain only that state
  my @retains;
  for (0..(@$universe-1)) {
    my $state = $universe->[$_];
    my $foo = $state->[$os];
    push(@retains, $_) if ("$foo" eq $rt);
  }
  if ($Quantum::Entanglement::destroy) {
    @$universe = @$universe[@retains];
    return $rt;
  }

  # set all non retained states to zero probability, leave others alone
  my $next_retain = shift @retains;
 PURGE: foreach my $snum ( 0..(@$universe-1) ) {
    if ($snum == $next_retain) {
      $next_retain = shift(@retains) || -1;
      next PURGE;
    }
    my $state = ${$universe}[$snum];
    $$state[$_] = 0 foreach grep {!($_ % 2)} (0..(@$state-1))
  }
  return $rt;
}

# numification (have to coerce things into numbers then strings for
# probability hash purposes, ick) (observation)
sub num_ent {
  my $c = $_[0];
  my $os = $c->[1];
  my $universe = ${$c->[0]};
  my %str_vals;
  # work out which state we want to retain
  foreach my $state (@$universe) {
    $str_vals{+$state->[$os]} =
               $state->[$os-1] + ($str_vals{+$state->[$os]}||0);
  }
  my ($hr, $ar) = _normalise(\%str_vals);
  my $rand = rand(1);
  my $rt;
 LOOP: foreach (@$ar) {
    if ( $rand < ${$hr}{$_}) {
      $rt = +$_;
      last LOOP;
    }
  }
  # retain only that state
  my @retains;
  for (0..(@$universe-1)) {
    my $state = $universe->[$_];
    my $foo = +$state->[$os];
    push(@retains, $_) if ($foo == $rt);
  }

  if ($Quantum::Entanglement::destroy) {
    @$universe = @$universe[@retains];
    return $rt;
  }

  # set probabilty to zero for each state we know can't be so
  my $next_retain = shift @retains;
 PURGE: foreach my $snum ( 0..(@$universe-1) ) {
    if ($snum == $next_retain) {
      $next_retain = shift(@retains) || -1;
      next PURGE;
    }
    my $state = ${$universe}[$snum];
    $$state[$_] = 0 foreach grep {!($_ % 2)} ( 0..(@$state-1) )
  }
  return $rt;
}

# boolean context (observation)
sub bool_ent {
  my $c = $_[0];
  my $os = $c->[1];
  my $universe = ${$c->[0]};
  my ($rt,$ft,$p_true, $p_false) = (0,0,0,0);
  my (@true, @false);

  foreach (0..(@$universe-1)) {
    my $state = $universe->[$_];
    my $c2 = $state->[$os];
    if ($c2) {
      $rt++;
      push @true, $_;
      $p_true += $state->[$os-1];
    }
    else {
      $ft++;
      push @false, $_;
      $p_false += $state->[$os-1];
    }
  }

  return 0 unless $rt;   # no states are true, so must be false
  return $rt unless $ft; # no states are false, so must be true
  # if it can be true, decide if it will end up being true or not
  my @retains;
  if ( _sel_output( $p_true,$p_false)
       or $Quantum::Entanglement::conform) {
    @retains = @true;
    $rt = $rt;
  }
  else {
    @retains = @false;
    $rt = 0;
  }

  if ($Quantum::Entanglement::destroy) {
    @$universe = @$universe[@retains];
    return $rt;
  }

  my $next_retain = shift @retains;
 PURGE: foreach my $snum ( 0..(@$universe-1) ) {
    if ($snum == $next_retain) {
      $next_retain = shift(@retains) || -1;
      next PURGE;
    }
    my $state = ${$universe}[$snum];
    $$state[$_] = 0 foreach grep {!($_ % 2)} (0..(@$state-1))
  }
  return $rt;
}

### any BInary, Non-observational OPeration
sub binop {
  my ($c,$d,$r,$code) = @_;
  my $var;
  my $universe;
  if ( ref($d)
       && UNIVERSAL::isa($d, 'Quantum::Entanglement')) {
    _join($c,$d);
    my $od = $d->[1]; my $oc = $c->[1];
    $var = _add($c);
    $universe = ${$c->[0]};
    foreach my $state (@$universe) {
      push @$state, ($state->[$oc-1] * $state->[$od-1],
                     &$code($state->[$oc],$state->[$od]) );
    }
  }
  else {        # adding something to one state
    my $oc = $c->[1];
    $var = _add($c);
    $universe = ${$c->[0]};
    if ($r) {
      push(@$_, ($_->[$oc-1], &$code($d,$_->[$oc]))) foreach @$universe;
    }
    else {
      push(@$_, ($_->[$oc-1], &$code($_->[$oc],$d))) foreach @$universe;
    }
  }
  return $var;
}

# any BInary Observational OPeration
sub bioop {
  my ($c, $d, $reverse, $code) = @_;
  my $rt = 0;
  my $ft = 0;
  my (@true, @false);
  my ($p_true, $p_false) = (0,0);
  my $universe;
  if (ref($d) && UNIVERSAL::isa($d, 'Quantum::Entanglement')) {
    $c->_join($d);
    $universe = ${$c->[0]};
    foreach (0..(@$universe-1)) {
      my $state = $universe->[$_];
      my $oc = $c->[1]; my $od = $d->[1];
      my $d2 = $state->[$od];
      my $c2 = $state->[$oc];
      if (&$code($c2, $d2)) {
        $rt++;
        push @true, $_;
        $p_true += $state->[$oc-1]* $state->[$od-1];
      }
      else {
        $ft++;
        push @false, $_;
        $p_false += $state->[$oc-1]* $state->[$od-1];
      }
    }
  }
  else {
    $universe = ${$c->[0]};
    foreach (0..(@$universe-1)) {
      my $state = $universe->[$_];
      my $d2 = $d;
      my $os = $c->[1];
      my $c2 = $state->[$os];
      ($c2, $d2) = ($d2, $c2) if $reverse;
      if (&$code($c2,$d2)) {
        $rt++;
        push @true, $_;
        $p_true += $state->[$os-1];
      }
      else {
        $ft++;
        push @false, $_;
        $p_false += $state->[$os-1];
      }
    }
  }

  return 0 unless $rt; # no states are true, so must be false
  return $rt unless $ft; # no states are false, so must be true
  my @retains;
  # if it can be true, decide if it will end up being true or not
  if ( _sel_output( $p_true,$p_false)
       or $Quantum::Entanglement::conform) {
    @retains = @true;
    $rt = $rt;
  }
  else {
    @retains = @false;
    $rt = 0;
  }

  if ($Quantum::Entanglement::destroy) {
    @$universe = @$universe[@retains];
    return $rt;
  }

  my $next_retain = shift @retains;
 PURGE: foreach my $snum ( 0..(@$universe-1) ) {
    if ($snum == $next_retain) {
      $next_retain = shift(@retains) || -1;
      next PURGE;
    }
    my $state = ${$universe}[$snum];
    $$state[$_] = 0 foreach grep {!($_ % 2)} (0..(@$state-1))
  }
  return $rt;

}

# any MUTating OPerator
sub mutop {
  my $c = $_[0];
  my $code = $_[1];
  my $os = $c->[1];
  my $universe = ${$c->[0]};
  foreach my $state (@$universe) {
    $state->[$os] = &$code($state->[$os]);
  }
  return $c;
}

sub unnop {
  my $c = $_[0];
  my $code = $_[1];
  my $os = $c->[1];
  my $val = $c->_add; my $universe = ${$c->[0]};
  foreach my $state (@$universe) {
    push(@$state, $state->[$os-1], &$code($state->[$os]) );
  }
  return $val;
}

##
# performing a conditional in paralell on the states (ie. without looking)
# returns a new variable

sub p_op {
  my ($arg1, $op, $arg2, $true_cf, $false_cf) = @_;
  $true_cf  = ref($true_cf)  ? $true_cf  : sub {1};
  $false_cf = ref($false_cf) ? $false_cf : sub {0};
  my $r = 0;
  unless (ref($arg1) && UNIVERSAL::isa($arg1, 'Quantum::Entanglement')) {
    $r = 1;
    ($arg1, $arg2) = ($arg2, $arg1);
  }
  my $tcref;
  eval "
     \$tcref = sub {
       local \*QE::arg1 = \\\$_[0];
       local \*QE::arg2 = \\\$_[1];
       if (\$_[0] $op \$_[1]) {
         return \&\$true_cf;
       }
       else {
         return \&\$false_cf;
       }
     }
  "; croak "$0: something wrong in p_op $@" if $@;

  return binop($arg1, $arg2, $r, $tcref);
}

# allows for other functions to be performed accross states, can take
# as many entangled variables as you like...
# can take code ref, or "symbolic" function name (eg. p_func('substr', ..))
sub p_func {
  my $func = shift;
  my $package = (caller)[0];
  # build up the function call by shifting off
  # entangled variables until something isn't entangled
  my $foo = ref($func) ? "&\$func(" : "$func(";
  my @temp = @_;
  my $first = $temp[0];
  do {
    my $c = shift @temp;
    _join($first,$c);
  } while (ref($temp[0]) && UNIVERSAL::isa($temp[0],'Quantum::Entanglement'));
  my @p_codes = ();
  do {
    my $c = shift;
    $foo .= '$state->[' . $c->[1] . '],';
    push @p_codes, $c->[1]-1;
  } while ( ref($_[0]) && UNIVERSAL::isa($_[0], 'Quantum::Entanglement'));
  $foo .= scalar(@_)? '@args);' : ');';
  my @args = @_;
  # loop over states, evaluating function in caller's package
  my $var = $first->_add;
  my $p_code = join('*', map {"\$state->[$_]"} @p_codes);
  my $universe = ${$first->[0]};
  foreach my $state (@$universe) {
    my $new_prob = eval $p_code;
    push(@$state, $new_prob, eval "package $package; $foo");
    croak "Internal error: $@" if $@;
  }
  return $var;
}

# This allows the introduction of new states into the system, based
# on the current values and probability amplitudes of current states
# must be given a code ref, followed by a list of entangled vars whose
# states will be passed to the function.
sub q_logic {
  my $func = shift;
  my (@offsets);
  my $first = $_[0];
  _join($first,$_) foreach @_;
  @offsets = map {$_->[1]-1, $_->[1]} @_;
  my $var = $first->_add;
  my $universe = ${$first->[0]};
  my @resultant_space;
  foreach my $state (@$universe) {
    my @new_states = &$func(@{$state}[@offsets]);
    do {
      push @resultant_space, [@$state, splice(@new_states,0,2)];
    } while (@new_states);
  }
  @{$universe} = @resultant_space;
  return $var;
}

# takes ft of amplitudes of a var, creates new state with the
# transformed amplitudes and the values from the first state.
sub QFT {
  my $c = $_[0];
  my $var = $c->_add;
  my $os = $c->[1];
  my $universe = ${$c->[0]};
  my @inputs = map {$_->[$os-1]} @$universe; # get current probs
  my $num = scalar @inputs;
  foreach my $r (0..($num-1)) {
    my $prob = 0;
    foreach my $x (0..($num-1)) {
      $prob += cplxe(1,(-2*pi*$r*$x / $num)) * $inputs[$x];
    }
    push @{$universe->[$r]}, $prob, $universe->[$r]->[$os];
  }
  return $var;
}

sub save_state{
  my @os;
  my $stash = [];

  foreach (@_) {
    carp "Can only save state of Quantum::Entanglement variables"
      unless (ref($_) && UNIVERSAL::isa($_, 'Quantum::Entanglement'));
  }

  my $first = $_[0];
  _join($first, $_) foreach @_;
  push(@os, $_->[1]) foreach @_;
  my $universe = ${$_[0]->[0]};
  foreach my $state (@$universe) {
    push @$stash, [ @{$state}[map {$_-1,$_} @os] ];
  }
  return bless $stash, 'Quantum::Entanglement::State';
}

# completely clobbers current state with whatever was saved previously
sub restore_state {
  my $stash = shift;

  my $num_saved = scalar(@{$stash->[0]}) /2;
  carp "You don't have any states saved!" unless $num_saved;
  my @newvars;
  $newvars[0] = _new();
  ${$newvars[0]->[0]}->[0] = ['fake','fake']; # no hackery here, no.
  if ($num_saved > 1) {
    for (2..$num_saved) {
      push(@newvars, $newvars[0]->_add());
      push @{${$newvars[0]->[0]}->[0]}, qw(fake fake); # or here, never
    }
  }
  my $universe = ${$newvars[0]->[0]};
  shift @$universe;
  foreach (@$stash) {
    push @$universe, [@$_];
  }
  return wantarray ? @newvars : $newvars[0];
}

# this is needed for simplicity of exporting save_states
package Quantum::Entanglement::State;
@Quantum::Entanglement::State::ISA = qw(Quantum::Entanglement);
sub DESTROY {}

1;

__END__;

=head1 NAME

Quantum::Entanglement - QM entanglement of variables in perl

=head1 SYNOPSIS

 use Quantum::Entanglement qw(:DEFAULT :complex :QFT);

 my $c = entangle(1,0,i,1);    # $c = |0> + i|1>
 my $d = entangle(1,0,1,1);    # $d = |0> + |1>

 $e = $c * $d; # $e now |0*0> + i|0*1> + |1*0> + i|1*1>, connected to $c, $d

 if ($e == 1) { # observe, probabilistically chose an outcome
   # if we are here, ($c,$d) = i|(1,1)>
   print "* \$e == 1\n";
 }
 else { # one of the not 1 versions of $e chosen
   # if we are here, ($c,$d) = |(0,0)> + i|(1,0)> + |(0,1)>
   print "* \$e != 1\n";
 }

=head1 BACKGROUND

 "Quantum Mechanics - the dreams that stuff is made of."

Quantum mechanics is one of the stranger things to have emerged from science
over the last hundred years.  It has led the way to new understanding
of a diverse range of fundamental physical phenomena and, should recent
developments prove fruitful, could also lead to an entirely new mode
of computation where previously intractable problems find themselves open
to easy solution.

While the detailed results of quantum theory are hard to prove, and
even harder to understand, there are a handful of concepts from the
theory which are more easily understood.  Hopefully this module will
shed some light on a few of these and their consequences.

One of the more popular interpretations of quantum mechanics holds that
instead of particles always being in a single, well defined, state
they instead exist as an almost ghostly overlay of many different
states (or values) at the same time.  Of course, it is our experience
that when we look at something, we only ever find it in one single state.
This is explained by the many states of the particle collapsing to a
single state and highlights the importance of observation.

In quantum mechanics, the
state of a system can be described by a set of numbers which have
a probability amplitude associated with them.
This probability amplitude is similar to the normal idea of probability
except for two differences.  It can be a complex number, which leads
to interference between states, and the probability with which we might
observe a system in a particular state is given by the modulus squared
of this amplitude.

Consider the simple system, often called a I<qubit>, which can take
the value of 0 or 1.  If we prepare it in the following superposition
of states (a fancy way of saying that we want it to have many possible
values at once):

  particle = 1 * (being equal to 1) + (1-i) * (being equal to 0)

we can then measure (observe) the value of the particle.  If we do
this, we find that it will be equal to 1 with a probability of

  1**2 / (1**2 + (1-i)(1+i) )

and equal to zero with a probability of

 (1+i)(1-i) / (1**2 + (1-i)(1+i) )

the factors on the bottom of each equation being necessary so that the chance
of the particle ending up in any state at all is equal to one.

Observing a particle in this way is said to collapse the wave-function,
or superposition of values, into a single value, which it will retain
from then onwards.  A simpler way of writing the equation above is
to say that

 particle = 1 |1> + (1-i) |0>

where the probability amplitude for a state is given as a 'multiplier'
of the value of the state, which appears inside the C<< | > >> pattern (this
is called a I<ket>, as sometimes the I<bra> or C<< <  | >>, pattern appears
to the left of the probability amplitudes in these equations).

Much of the power of quantum computation comes from collapsing states
and modifying the probability with which a state might collapse to a
particular value as this can be done to each possible state at the same
time, allowing for fantastic degrees of parallelism.

Things also get interesting when you have multiple particles together
in the same system.  It turns out that if two particles which exist
in many states at once interact, then after doing so, they will be
linked to one another so that when you measure the value of one
you also affect the possible values that the other can take.  This
is called entanglement and is important in many quantum algorithms.

=head1 DESCRIPTION

Essentially, this allows you to put variables into a superposition
of states, have them interact with each other (so that all states
interact) and then observe them (testing to see if they satisfy
some comparison operator, printing them) which will collapse
the entire system so that it is consistent with your knowledge.

As in quantum physics, the outcome of an observation will be the result
of selecting one of the states of the system at random.  This might
affect variables other than the ones observed, as they are able to
remember their history.

For instance, you can say:

 $foo = entangle(1,0,1,1); # foo = |0> + |1>
 $bar = entangle(1,0,1,1); # bar = |0> + |1>

if at this point we look at the values of $foo or $bar, we will
see them collapse to zero half of the time and one the other half of
the time.  We will also find that us looking at $foo will have no
effect on the possible values, or chance of getting any one of those
values, of $bar.

If we restrain ourselves a little and leave $foo and $bar unobserved
we can instead play some games with them.  We can use our entangled
variables just as we would any other variable in perl, for instance,

 $c = $foo * $bar;

will cause $c to exist in a superposition of all the possible outcomes
of multiplying each state of $foo with each state in $bar.  If we
now measure the value of $c, we will find that one quarter of the time
it will be equal to one, and three quarters of the time it will be equal
to zero.

Lets say we do this, and $c turns out to be equal to zero this time, what
does that leave $foo and $bar as?  Clearly we cannot have both $foo and
$bar both equal to one, as then $c would have been equal to one, but all
the other possible values of $foo and $bar can still occur.  We say
that the state of $foo is now entangled with the state of $bar so that

 ($foo, $bar ) = |0,0> + |0,1> + |1,0>.

If we now measure $foo, one third of the time it will be equal to one and
two thirds of the time, it will come out as zero.  If we do this and get
one, this means that should we observe $bar it will be equal to zero so
that our earlier measurement of $c still makes sense.

=head1 Use of this module

To use this module in your programs, simply add a

 use Quantum::Entanglement;

line to the top of your code,  if you want to use complex probability
amplitudes, you should instead say:

 use Quantum::Entanglement qw(:complex :DEFAULT);

which will import the C<Math::Complex i Re Im rho theta arg cplx cplxe>
functions / constants into your package.

You can also import a Quantum Fourier transform, which acts on the
probability amplitudes of a state (see below) by adding a C<:QFT>
tag.

This module adds an C<entangle> function to perl, this puts a
variable into multiple states simultaneously.  You can then
cause this variable to interact with other entangled, or normal,
values the result of which will also be in many states at once.

The different states which a variable can take each have an associated
complex probability amplitude, this can lead to interesting behaviour,
for instance, a root-not logic gate (see q_logic, below).

=head2 entangle

This sets up a new entangled variable:

 $foo = entangle(prob1, val1, prob2, val2, ...);

The probability values are strictly speaking probability amplitudes,
and can be complex numbers (corresponding to a phase or wave-ish
nature (this is stretching things slightly...)).  To use straight
numbers, just use them, to use complex values, supply a Math::Complex
number.

Thus

 $foo = entangle(1,  0, 1+4*i, 1);

corresponds to:

 foo = 1|0> + (1 + 4i)|1>

The probabilities do not need to be normalized, this is done
by the module whenever required (ie. when observing variables).

=head2 Non-observational operations

We can now use our entangled variable just as we would any normal
variable in perl.  Much of the time we will be making it do things
where we do not find anything out about the value of our variable,
if this is the case, then the variable does not collapse, although
any result of its interactions will be entangled with itself.

=head2 Observational Operators

Whenever you perform an operation on an entangled variable which
should increase your level of knowledge about the value of the variable
you will cause it to collapse into a single state or set of states.
All logical comparison (C<==>, C<gt> ....) operators, as well as
string and num -ifying and boolean observation will cause collapse.

When an entangled variable is observed in this way, sets of states which
would satisfy the operator are produced (ie. for $a < 2, all states <2 and
all >= 2).  One of these sets of states is then selected randomly, using
the probability amplitudes associated with the states.  The result of
operating on this state is then returned.  Any other states are then
destroyed.

For instance, if

 $foo = entangle(1,2,1,3,1,5,1,7);
        # |2> +|3> + |5> +|7>
then saying

 print '$foo is greater than four' if ($foo > 4);

will cause $foo to be either C<< |2> + |3> >> B<or> C<< |5> +7> >>.

Of course, if you had said instead:

  $foo = entangle(-1,2,1,3,1,5,1,7);
           # -1|2> + |3> + |5> +|7>

then if C<$foo> was measured here, it would come out as any one of 2,3,5,7
with equal likelyhood (remember, amplitude squared).  But saying

 print '$foo is greater than four' if ($foo > 4);

will cause foo to be C<< |2> or 3> >> with a probability of C<(-1 + 1) == 0> or
C<< |5 or 7> >> with probability of C<(1 + 1)/2 == 1>.  Thus C<< $foo > 4 >>
will B<always> be true.

It is possible to perform operations like these on an entangled
variable without causing collapse by using C<p_op> (below).

When performing an observation, the module can do two things to
the states which can no longer be valid (those to which it did not collapse,
|2 or 3> in the example above).  It can either internally
set the probability of them collapsing to be zero or it can delete
them entirely.  This could have consequences if you are writing parallel
functions that rely on there being a certain number of states in
a variable, even after collapse.

The default is for collapsed states to be destroyed, to alter this
behaviour, set the C<$Quantum::Entanglement::destroy> variable to
a false value.  In general though, you can leave this alone.

=head2 Dammit Jim, I can't change the laws of physics

Although not the default, it is possible to cause observation (for
boolean context or with comparison operators only) to act in a more
purposeful manner.  If the variable:

 $Quantum::Entanglement::conform

has a true value, then the overloaded operations provided by this
module will try their very best to return "truth" instead of
selecting randomly from both "true" and "false" outcomes.

For example:

 $foo = entangle(1,0,1,1,1,3); # foo = |0> + |1> + |3>
 $Quantum::Entanglement::conform = 1;
 print "\$foo > 0\n" if $foo > 0;
                               # foo now = |1> + |3>
 print "\$foo == 3\n" if $foo == 3;
                               # foo now = |3>

will always output:

 $foo > 0
 $foo == 3

Of course, setting this variable somewhat defeats the point of
the module, but it could lead to some interesting pre-calculating
algorithms which are fed with entangled input, which is then
later defined (by testing ==, say )with the answer of the calculation
appearing, as if by magic, in some other variable.  See also the
section L<save_state>.

=head2 p_op

This lets you perform conditional operations on variables in a
superposition of states B<without actually looking at them>.
This returns a new superposed variable, with states given by
the outcome of the p_op.  You cannot, of course, gain any information
about the variables involved in the p_op by doing this.

 $rt = p_op(var1, op, var2, code if true, code if false).

C<op> should be a string representing the operation to be performed
(eg. C<"==">).  The two code arguments should be references to subs
the return values of which will be used as the value of the
corresponding state should the expression be true or false.

If no code is provided, the return value of the operator itself is
evaluated in boolean context, if true, 1 or if false, 0 is
used as the corresponding state of the returned variable.  Only one
of var1 and var2 need to be entangled states.  The values of the states
being tested are placed into the $QE::arg1 and $QE::arg2 variables
should the subroutines want to play with them (these are localized
aliases to the actual values, so modify at your peril (or pleasure)).

The semantics are best shown by example:

 $gas = entangle(1, 'bottled', 1, 'released');
   # gas now in states |bottled> + |released>

 $cat_health = p_op($gas, 'eq', 'released',
                         sub {'Dead'},
                         sub {'Alive'});
   # cat,gas now in states |Alive, bottled> + |Dead, released>

This is similar to parallel execution of the following psuedo code:

 if (gas is in bottle) { # not probabilistic, as we don't look
   cat is still alive
 }
 else {
   cat is dead
 }

The cat can now be observed (with a conditional test say) and doing so will
collapse both the cat and the gas:

 if ($cat_health eq 'Dead') {# again, outcome is probabilistic
   # thus gas = |released>
 }
 else {
   # thus gas = |bottled>
 }

This also lets you use some other 'binary' operators on a superposition
of states by immediatly observing the return value of the parallel op.

 $string = entangle(1,'aa', 1, 'bb', 1, 'ab', 1, 'ba');
 $regex = qr/(.)\1/;

 if (q_op($string, '=~', $regex)) { # again, probabilistic
   # if here, string = |aa> + |bb>
 }
 else {
   # if here, string = |ab> + |ba>
 }

=head2 p_func

This lets you perform core functions and subs through the states
of a superposition without observing and produce a new variable
corresponding to a superposition of the results of the function.

 p_func("func" ,entangled var,[more vars,] [optional args])

Any number of entangled variables can be passed to the function,
optional args begin with the first non-entangled var.

The optional args will be passed to the subroutine or function unmodified.

eg. C<p_func('substr', $foo, 1,1)> will perform C<substr($state, 1,1)>
on each state in $foo.  Saying C<p_func('substr', $foo,$bar,1)> will
evaluate C<substr($s_foo, $s_bar,1)> for each state in $foo and $bar.

You can also specify a subroutine, either in the same package that C<p_func>
is called from, or with a fully qualified name.

 sub foo {my $state = $_[0]; return ${$_[1]}[$state]}
 @foo = qw(one two three);
 $foo = entangle(1,1,1,2,1,3); # |1> + |2> + |3>
 $bar = p_func('foo', $foo, \@foo);

 # bar now |one> + |two> + |three>

You can also pass a code reference as first arg (cleaner)...

 $bar = p_func(\&foo, $foo, \@foo);

=head2 q_logic

This allows you to create new states, increasing the amount of
global state as you do so.  This lets you apply weird quantum
logic gates to your variables, amongst other things.

 q_logic(code ref, entangled var [,more vars] );

The code ref is passed a list of probabilities and values corresponding
to the state currently being examined. (prob, val, [prob, val..])
code ref must return a list of the following format:

 (prob, val, prob, val ...) # as entangle basically

For instance, this is a root-not gate:

 sub root_not {
   my ($prob, $val) = @_;
   return( $prob * (i* (1/sqrt(2))), $val,
	   $prob * (1/sqrt(2)), !$val ? 1 : 0);
 }

 $foo = entangle(1,0);
 $foo = q_logic(\&root_not, $foo);

 # if $foo is observed here, it will collapse to both 0 and 1, at random

 $foo = q_logic(\&root_not, $foo);

 print "\$foo is 1\n" if $foo; # always works, $foo is now 1.

This corresponds to the following:

 foo = |0>

 root_not( foo )

 foo is now in state: sqrt(2)i |0> + sqrt(2) |1>

 root_not (foo)

 foo in state: (0.5 - 0.5) |0> + (0.5i + 0.5i) |1>

 which if observed gives

 foo = 0|0> + i|1> which must collapse to 1.

Neat, huh?

=head2 save_state

Having set up a load of entangled variables, you might wish to
store their superposed state for later restoration.  This is acheived
using the C<save_state> function:

 $state = save_state( [list of entangled variables] );

To restore the states of the entangled variables, simply call
the C<restore_state> method on the C<$state>:

  ($foo, $bar) = $state->restore_state;

The variables return by C<restore_state> will no longer be entangled to
anything they were previously connected to.  If multiple variables have
their state saved at once, then any connections between them will remain.

See the demo calc_cache for an example of use.

=head2 QFT

This provides a quantum fourier transform which acts on the probability
amplitudes of a state, creating a new state with the same values as the
initial state but with new probability amplitudes.  FTs like this are
used in many quantum algorithms where it is important to find the
periodicity of some function (for instance, Shor).

This will only work if you have carefully populated your states, essentially
if all seperately C<entangle>d variables do not interact.  This
sort of breaks encapsulation, so might change in the future!

See C<~/demo/shor.pl> for an example of the use of this function.

=head2 Quantum::Entanglement::show_states

This allows you to find out the states that your variables are in, it
does not count as observation.

If called as a method it will
only return the states available to that variable, thus:

 $foo = entangle(1,0,1,1);
 print $foo->show_states;

outputs:

 1|0>   1|1>

If a variable is entangled with other superposed values, then calling
C<save_state> with an additional true argument will display the states
of all the variables which have interacted together.

 print $foo->show_states(1);

If two variables have not yet interacted, then they will not appear in
the state space of the other.

The ordering of the output of this function may change in later versions
of this module.

=head2 Entangling subroutines

It is possible to entangle a set of subroutine references and later
call them in parallel with the same set of arguments.  The subroutines
will always be called in scalar context.  The return values of the
subroutines will be present in the entangled variable returned.

eg.

 $subs = entangle(1 => sub {return $_[0}, 1=>sub {return $_[1]});
 $return = $subs->(qw(chalk cheese));
  # $return now |chalk> + |cheese>

=head1 EXPORT

This module exports quite a bit, C<entangle>, C<save_state>,
C<p_op>, C<p_func> and C<q_logic>.  If used with qw(:complex) it will
also export the following functions / constants from the Math::Complex
module: C<i Re Im rho theta arg cplx cplxe>.

=head1 AUTHOR

Alex Gough (F<alex@earth.li>).  Any comments, suggestions or bug
reports are warmly welcomed.

=head1 SEE ALSO

perl(1).  L<Quantum::Superpositions>. L<Math::Complex>.
L<http://www.qubit.org/resource/deutsch85.ps>
 - 1985 Paper by David Deutsch.
L<http://xxx.lanl.gov/abs/math.HO/9911150>
 - Machines, Logic and Quantum Physics,
      David Deutsch, Artur Ekert, Rossella Lupacchini.

Various examples are provided in the C<~/demo/> directory of the
distribution.  An article on the module is available at
L<http://the.earth.li/~alex/quant_ent.html>.

=head1 BUGS

This is slow(ish) but fun, so hey!

=head2 Shortcomings

This module does fall short of physical reality in a few important
areas, some of which are listed below:

=over 4

=item No eigenfunction like behaviour

All operators share the same set of eigenfunctions, in real QM this
is sometimes not the case, so observing one thing would cause some
other thing (even if already observed) to fall into a superposition
of states again.

=item Certain observables cannot simultaneously have precisely defined values.

This follows from the point above.  The famous uncertainty
principle follows from the fact that position and momentum have different
sets of eigenfunctions.  In this module, it is always possible to collapse
the system so that a value is known for every entangled variable.

=item Perl is not a quantum computing device

Perl, alas, is currently only implemented on classical computers, this
has the disadvantage that any quantum algorithm will not run in constant
time but will quite likely run in exponential time.  This might be
remedied in future releases of perl.  Just not anytime soon.

=item Quantum information cannot be copied with perfect fidelity

It is impossible to perfectly clone a real entangled state without
'damaging' in some way either the original or the copy.  In this
module, it is possible for this to happen as we have special
access to the states of our variables.

=item Cannot generate perfectly random numbers

It is well known that classical computers cannot produce a perfectly
random sequence of numbers, as this module runs on one of these, it
also suffers the same fate.  It is possible to give a classical computer
access to a perfect random number generator though (essentially by
linking it to a suitable physical system) in which case this is no
longer a problem.

=back

=head1 COPYRIGHT

This code is copyright (c) Alex Gough, 2001,2002.  All Rights
Reserved.  This module is free software.  It may be used,
redistributed and/or modified under the same terms as Perl itself.

=cut
