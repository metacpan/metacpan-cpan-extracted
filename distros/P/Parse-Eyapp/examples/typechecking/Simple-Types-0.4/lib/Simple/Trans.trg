/* Scope Analysis */
blocks:  /BLOCK|FUNCTION|PROGRAM/

/* Just for you to think about */
deleteemptyblocks: BLOCK and { %{$BLOCK->{symboltable}}+$BLOCK->children == 0 }
  => { $deleteemptyblocks->delete() }

moveemptyblocks2sts: BLOCK and { %{$BLOCK->{symboltable}} == 0 }
  => { $_[0]->type('STATEMENTS'); }

retscope: /FUNCTION|RETURN/

/***************** Jacobo bug *********************/
loop_control: /BREAK|CONTINUE|WHILE/
/***************** Type Checkers *****************/

{
  
  my $types; # reference to the hash containing the type table 
  my ($INT, $CHAR, $VOID);

  sub type_error {
    my $msg = shift;
    my $line = shift;
     die "Type Error at line $line: $msg\n"
  }

  sub set_types {
    my $root = shift;
    $types = $root->{types};
    $INT = $types->{INT};
    $CHAR = $types->{CHAR};
    $VOID = $types->{VOID};
  }

  sub char2int {
    my ($node, $i) = @_;

    my $child = $node->child($i);
    return $child unless $child->{t} == $CHAR;

    my $coherced = Parse::Eyapp::Node->new('CHAR2INT', sub { $_[0]->{t} = $INT });
    $coherced->children($child);  # Substituting $node(..., $child, ... )
    $node->child($i, $coherced);  # by           $node(..., CHAR2INT($child), ...)

    return $coherced;
  }

  sub int2char {
    my ($node, $i) = @_;

    my $child = $node->child($i);
    return $child unless $child->{t} == $INT;

    my $coherced = Parse::Eyapp::Node->new('INT2CHAR', sub { $_[0]->{t} = $CHAR });
    $coherced->children($child); # Substituting $node(..., $child, ... )
    $node->child($i, $coherced); # by           $node(..., INT2CHAR($child), ...)

    return $coherced;
  }

}
# Give type to the constants
inum: INUM($x) => { $_[0]->{t} = $INT }
charconstant: CHARCONSTANT($x) => { $_[0]->{t} = $CHAR }

statements: /STATEMENTS|PROGRAM|BREAK|CONTINUE/ => { $_[0]->{t} = $VOID }

# Binary Operations
bin: / PLUS
      |MINUS
      |TIMES
      |DIV
      |MOD
      |GT
      |GE
      |LE
      |EQ
      |NE
      |LT
      |AND
      |EXP
      |OR
     /($x, $y)
  => { 
    $x = char2int($_[0], 0);
    $y = char2int($_[0], 1);
    
    if (($x->{t} == $INT) and ( $y->{t} == $INT)) {
      $_[0]->{t} = $INT;
      return 1;
    }
    type_error("Incompatible types with operator '".($_[0]->lexeme)."'", $_[0]->line);
  }

{ # support for arrays

  sub compute_dimensionality {
    my $t = shift;
    my $i = 0;
    my $q;
    my $used_dim = scalar(@_);
    for ($q=$t; is_array($q) and ($i < $used_dim); $q=$q->child(0)) {
      $i++ 
    }

    croak "Error checking array type\n" unless defined($q);
    return ($i, $used_dim, $q);
  }

  sub is_array {
    my $type = shift;
    
    defined($type) && $type =~ /^A_\d+/;
  }

  sub array_compatible {
    my ($a1, $a2) = @_;

    return 1 if $a1 == $a2;
    # int a[10][20] and int b[5][20] are considered compatibles
    return (is_array($a1) && is_array($a2) && ($a1->child(0) == $a2->child(0)));
  }
}

arrays: VARARRAY($x, INDEXSPEC(@y))
   => {

    my $t = $VARARRAY->{t}; # Type declared for VARARRAY
      type_error(           # Must be an array type
        " Variable '$x->{attr}[0]' was not declared as array",
        $VARARRAY->line
      )
    unless is_array($t);

    my ($declared_dim, $used_dim, $ret_type) = compute_dimensionality($t, @y);

      type_error(
        " Variable '$x->{attr}[0]' declared with less than $used_dim dimensions",
        $VARARRAY->line
      )
    unless $declared_dim >= $used_dim;

    for (0..$#y) { # chack that each index is integer. Coherce it if is $CHAR
      my $ch = char2int($INDEXSPEC, $_);

        type_error("Indices must be integers",$VARARRAY->line) 
      unless ($ch->{t} == $INT);
    }

    $VARARRAY->{t} = $ret_type;
    
    return 1;
  }
       
assign: /ASSIGN
         |PLUSASSIGN
         |MINUSASSIGN
         |TIMESASSIGN
         |DIVASSIGN
         |MODASSIGN
        /:asgn($lvalue, $exp) 
  => {
    my $lt =  $lvalue->{t};
    $exp = char2int($asgn, 1) if $lt == $INT;
    $exp = int2char($asgn, 1) if $lt == $CHAR;

      type_error("Incompatible types in assignment!", $asgn->line)
    unless ($lt == $exp->{t});

      type_error("The C language does not allow assignments to non-scalar types!", $asgn->line)
    unless ($lt == $INT) or ($lt == $CHAR); # Structs will also be allowed

    # Assignments are expressions. Its type is the type of the lhs or the rhs
    $asgn->{t} = $lt;

    # Make explicit the type of assignment, i.e.  s/PLUSASSIGN/PLUSASSIGNINT/
    $asgn->type(ref($asgn).ref($lt)); 

    return 1;
  }

control: /IF|IFELSE|WHILE/:con($bool) 
  => {
    $bool = char2int($con, 0);

      type_error("Condition must have integer type!", $bool->line)
    unless $bool->{t} == $INT;

    $con->{t} = $VOID;

    return 1;
  }


functioncall: FUNCTIONCALL($f, ARGLIST)
  => {
    # Before type checking attribute "t" has the declaration of $f
    my $ftype = $FUNCTIONCALL->{t};  

     type_error(" Variable '".$f->value."' was not declared as function", $f->line)
    unless $ftype->isa("F");

    my @partypes = $ftype->child(0)->children;

    my @args = $ARGLIST->children;    # actual arguments
    my $numargs = @args;    # Number of actual arguments
    my $numpar = @partypes; # Number of declared parameters

    # Check number of args
      type_error("Function '".$f->value."' called with $numargs args expected $numpar",$f->line)
    if ($numargs != $numpar);

    # Check type compatibility between args
    # Do type cohercion if needed
    for (0..$#args) {
      my $pt = shift @partypes;
      my $ch = $ARGLIST->child($_);
      $ch = char2int($ARGLIST, $_) if $pt == $INT;
      $ch = int2char($ARGLIST, $_) if $pt == $CHAR;

      my $cht = $ch->{t};
      unless (array_compatible($cht, $pt)) {
        type_error(
          "Type of argument " .($_+1)." in call to " .$f->value." differs from expected", 
          $f->line
        )
      }
    }
    
    # Now attribute "t" has the type of the node
    $FUNCTIONCALL->{t} = $ftype->child(1);
    return 1;
  }

/* TIMTOWTDI when MOPping */
return: RETURN(.) 
bind_ret2function: FUNCTION
  => {
    my @RETURNS = $return->m($FUNCTION);
    @RETURNS = map { $_->node } @RETURNS;

    # Set "returns" attribute for the FUNCTION node
    $FUNCTION->{returns} = \@RETURNS;

    my $exp;
    my $return_type = $FUNCTION->{t}->child(1);
    for (@RETURNS) {

      # Set "function" attribute for each RETURN node
      $_->{function} = $FUNCTION; 

      #always char-int conversion
      $exp = char2int($_, 0) if $return_type == $INT;
      $exp = int2char($_, 0) if $return_type == $CHAR;

        type_error("Returned type does not match function declaration",
                                                              $_->line)
      unless $exp->{t} == $return_type;
      $_->type("RETURN".ref($return_type));

    }

    return 1;
  }

returntype: RETURN($ch)
  => {
      my $rt = $RETURN->{t};

      $ch = char2int($RETURN, 0) if $rt == $INT;
      $ch = int2char($RETURN, 0) if $rt == $CHAR;

        type_error("Type error in return statement", $ch->line)
      unless ($rt == $ch->{t});

      # $RETURN->{t} has already the correct type

      $RETURN->type(ref($RETURN).ref($rt));

      return 1;
  }

