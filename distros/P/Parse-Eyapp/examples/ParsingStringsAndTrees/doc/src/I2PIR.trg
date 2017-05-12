{ #  Example of support code
  use List::Util qw(reduce);
  my %Op = (PLUS=>'+', MINUS => '-', 
            TIMES=>'*', DIV => '/');
}
algebra = fold wxz zxw neg;

fold: /TIMES|PLUS|DIV|MINUS/:b(NUM, NUM) 
=> { 
  my $op = $Op{ref($b)};
  $NUM[0]->{attr} = eval  
  "$NUM[0]->{attr} $op $NUM[1]->{attr}";
  $_[0] = $NUM[0]; 
}
zxw: TIMES(NUM, .) and {$NUM->{attr} == 0}
=> { $_[0] = $NUM }
wxz: TIMES(., NUM) and {$NUM->{attr} == 0} 
=> { $_[0] = $NUM }
neg: NEG(NUM) 
=> { $NUM->{attr} = -$NUM->{attr}; 
     $_[0] = $NUM }

{{ my $num = 1; # closure
  sub new_N_register {
    return '$N'.$num++;
  }
}}

reg_assign: $x  
  => { 
    if (ref($x) =~ /VAR|NUM/) {
      $x->{reg} = $x->{attr};
      return 1;
    }
    if (ref($x) =~ /ASSIGN/) {
      $x->{reg} = $x->child(0)->{attr};
      return 1;
    }
    $_[0]->{reg} = new_N_register(); 
  }


translation = t_num t_var t_op t_neg 
             t_assign t_list t_print;

t_num: NUM 
  => { $NUM->{tr} = $NUM->{attr} }
{ our %s; }
t_var: VAR => {
    $s{$_[0]->{attr}} = "num";
    $_[0]->{tr} = $_[0]->{attr};
  }
t_op:  /TIMES|PLUS|DIV|MINUS/:b($x, $y) 
  => {
    my $op = $Op{ref($b)};
    $b->{tr} = "$b->{reg} = $x->{reg} "
                   ."$op $y->{reg}"; 
  }
t_neg: NEG($exp) => {
  $NEG->{tr} = "$NEG->{reg} = - $exp->{reg}";
}

t_assign: ASSIGN($v, $e) => { 
  $s{$v->{attr}} = "num";
  $ASSIGN->{tr} = "$v->{reg} = $e->{reg}" 
}

{ my $cr = '\\n'; }
t_print: PRINT(., $var)
  => {
    $s{$var->{attr}} = "num";
    $PRINT->{tr} =<<"EOP";
print "$var->{attr} = "
print $var->{attr}
print "$cr"
EOP
  }

{
  # Concatenates the translations of the subtrees
  sub cat_trans {
    my $t = shift;

    my $tr = "";
    for ($t->children) {
      (ref($_) =~ m{NUM|VAR|TERMINAL}) 
        or $tr .= cat_trans($_)."\n" 
    }
    $tr .= $t->{tr} ;
  }
}

t_list: EXPS(@S) 
  => {
    $EXPS->{tr} = "";
    my @tr = map { cat_trans($_) } @S;
    $EXPS->{tr} = 
      reduce { "$a\n$b" } @tr if @tr;
  }

