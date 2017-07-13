package Neo4j::Cypher::Abstract::Peeler;
use Carp;
use List::Util 1.33 qw(any);
use Scalar::Util qw(looks_like_number blessed);
use strict;
use warnings;

# quoting logic:
# if config:bind = true
# if anon_placeholder (like ?) is in config, then return literals without
# quoting in array $obj->bind_values, and the placeholder in the statement
# if anon_placeholder is undef, then return literals quoted directly in the
# statement; return named parameters in $obj->parameters
# 
# if config:bind false
# leave tokens and identifiers as-is, no bind_values or parameters

our $VERSION = '0.1002';
my $SQL_ABSTRACT = 1;

sub puke(@);
sub belch(@);

my %config = (
  bind => 1,
  anon_placeholder => undef, # '?',
  hash_op => '-and',
  array_op => '-or',
  list_braces => '[]',
  ineq_op => '<>',
  implicit_eq_op => '=',
  quote_lit => "'",
  esc_quote_lit => "\\",
  parameter_sigil => qw/^([:$?])|({[^}]+}$)/,
  quote_fld => undef,
  safe_identifier => qw/[a-zA-Z_.]+/
);

# for each operator type (key in %type_table), there
# should be a handler with the same name

my %type_table = (
  infix_binary => [qw{ - / %  =~ = <> < > <= >=
		       -contains -starts_with -ends_with}],
  infix_listarg => [qw{ -in } ],
  infix_distributable => [qw{ + * -and -or }],
  prefix => [qw{ -not }],
  postfix => [qw{ -is_null -is_not_null }],
  function => [qw{
		   ()
		   -abs -ceil -floor -rand -round -sign -degrees
		   -e -exp -log -log10 -sqrt -acos -asin -atan -atan2
		   -cos -cot -haversin -pi -radians -sin -tan
		   -exists -toInt
		   -left -lower -ltrim -replace -reverse -right
		   -rtrim -split -substring -toString -trim -upper
		   -length -size -type -id -coalesce -head -last
		   -labels -nodes -relationships -keys -tail -range
		   -collect -count -max -min -percentileCont
		   -percentileDisc -stDev -stDevP -sum
		   -shortestPath -allShortestPaths
	       }],
  predicate => [qw{ -all -any -none -single -filter}],
  extract => [qw{ -extract }],
  reduce => [qw{ -reduce }],
  list => [qw( -list )], # returns args in list format
  bind => [qw( -bind )], # handles parameters and literal quoting
  thing => [qw( -thing )], # the literal thing itself
 );

my %dispatch;
foreach my $type (keys %type_table) {
  no strict 'refs';
  my @ops = @{$type_table{$type}};
  @dispatch{@ops} = ( *${type}{CODE} ) x @ops;
}

sub new {
  my $class = shift;
  my %args = @_;
  if ($args{dispatch} and !(ref $args{dispatch} eq 'HASH')) {
    puke "dispatch must be hashref mapping operators to coderefs (or absent)"
  }
  if ($args{config} and !(ref $args{config} eq 'HASH')) {
    puke "config must be hashref defining peeler options"
  }
  my $self = {
    dispatch => $args{dispatch} || \%dispatch,
    config => $args{config} || \%config
   };
  # update config elts according to constructor args
  if (length scalar keys %args) {
    for (keys %config) {
      defined $args{$_} and $self->{config}{$_} = $args{$_};
    }
  }
  bless $self, $class;
}

sub belch (@) {
  my($func) = (caller(1))[3];
  Carp::carp "[$func] Warning: ", @_;
}

sub puke (@) {
  my($func) = (caller(1))[3];
  Carp::croak "[$func] Fatal: ", @_;
}

sub bind_values { $_[0]->{bind_values} ? @{$_[0]->{bind_values}} : return ; }
sub parameters { $_[0]->{parameters} ? @{$_[0]->{parameters}} : return ; }

sub _dispatch {
  $_[0]->{dispatch}{$_[1]}->(@_);
}

sub _quote_lit {
  my $arg = "$_[1]";
  my $q = $_[0]->{config}{quote_lit};
  if (looks_like_number $arg or
	$arg =~ /^\s*$q(.*)$q\s*$/ or
	$arg =~ $_[0]->{config}{parameter_sigil} or
	blessed($_[1])
       ) {
    # numeric, already quoted, a parameter, or an object
    return "$arg";
  }
  else {
    my $e = $_[0]->{config}{esc_quote_lit};
    $arg =~ s/$q/$e$q/g;
    return "$q$arg$q";
  }
}

sub _quote_fld { # noop
  return $_[1];
}

sub express {
  my $self = shift;
  my $x = $_[0];
  if ($SQL_ABSTRACT) {
    $x = $self->canonize($x);
  }
  return $self->peel($x);
}

sub config {
  my $self = shift;
  my ($key, $val) = @_;
  if (!defined $key) {
    return %{$self->{config}};
  }
  elsif (!defined $val) {
    return $self->{config}{$key};
  }
  else {
    return $self->{config}{$key} = $val;
  }
}


# canonize - rewrite mixed hash/array expressions in canonical lispy
# array format - interpret like SQL::A
sub canonize {
  my $self = shift;
  my ($expr) = @_;
  my $ret = [];
  my ($do,$is_op);
  $is_op = sub {
    if (!defined $_[0] || ref $_[0]) {
      return 0;
    }
    if (!$_[1]) {
      if (defined $self->{dispatch}{$_[0]}) {
	1;
      }
      else {
	puke "Unknown operator '$_[0]'" if (
	  $_[0] !~ /$$self{config}{safe_identifier}/ and
	  $_[0]=~/^-|[[:punct:]]/ and !looks_like_number($_[0])
	 );
	0;
      }
    }
    else {
      grep /^\Q$_[0]\E$/, @{$type_table{$_[1]}};
    }
  };
  my $level=0;
  $do = sub {
    my ($expr, $lhs, $arg_of) = @_;
    for (ref $expr) {
      ($_ eq '' or blessed($expr)) && do {
	if (defined $expr) {
	  # literal (value?)
	  return $self->{config}{bind} ? [ -bind => $expr ] : $expr;
	}
	else {
	  puke "undef not interpretable";
	}
      };
      /REF|SCALAR/ && do { # literals
	if ($_ eq 'SCALAR') {
	  return [-thing => $$expr] ; # never bind
	}
	elsif (ref $$expr eq 'ARRAY') {
	  # very SQL:A thing, but we'll do it
	  my @a = @$$expr;
	  my $thing = shift @a;
	  @a = map { $self->_quote_lit($_) } @a;
	  if ($self->{config}{bind}) {
	    push @{$self->{bind_values}}, @a;
	  }
	  else {
	    if ($self->{config}{anon_placeholder}) {
	      ($thing =~ s/\Q$$self{config}{anon_placeholder}\E/$_/) for @a;
	    }
	  }
	  return $lhs ? [-thing => $lhs, [-thing => $thing]] : [-thing => $thing];
	}
      };
      /ARRAY/ && do {
	if ($is_op->($$expr[0],'infix_distributable')) {
	  # handle implicit equality pairs in an array
	  my $op = shift @$expr;
	  my (@args,@flat);
	  # flatten
	  if (@$expr == 1) {
	    for (ref($$expr[0])) {
	      /ARRAY/ && do {
		@flat = @{$$expr[0]};
		last;
	      };
	      /HASH/ && do {
		@flat = %{$$expr[0]};
		last;
	      };
	      puke 'Huh?';
	    };
	  }
	  else {
	    @flat = @$expr; # already flat
	  }
	  while (@flat) {
	    my $elt = shift @flat;
#	    $DB::single=1 if !defined($elt);
	    if (!ref $elt) { # scalar means lhs of a pair or another op
	      push @args, $do->({$elt => shift @flat},$lhs,$op);
	    }
	    else {
	      next if (ref $elt eq 'ARRAY') && ! scalar @$elt or
		(ref $elt eq 'HASH') && ! scalar %$elt; 
	      push @args, $do->($elt,$lhs,$op);
	    }
	  }
 	  return [$op => @args];
	}
	if ($is_op->($$expr[0]) and !$is_op->($$expr[0],'infix_distributable')) {
	  # some other op
	  return [ $$expr[0] => map {
	    $do->($_,undef,$$expr[0])
	  } @$expr[1..$#$expr] ];
	}
	elsif (ref $$expr[0] eq 'HASH') { #?
	  return [ $self->{config}{array_op} =>
		     map { $do->($_,$lhs,$self->{config}{array_op}) } @$expr ];
	}
	else { # is a plain list
	  if ($lhs) {
	    # implicit equality over array default op
	    return [ $self->{config}{array_op} => map {
	      defined() ?
		[ $self->{config}{implicit_eq_op} => $lhs,
		  $do->($_,undef,$self->{config}{implicit_eq_op}) ] :
		[ -is_null => $lhs ]
	    } @$expr ];
	  }
	  else {
	    if ($arg_of and any { $is_op->($arg_of, $_) }
		  qw/function infix_listarg predicate reduce/
	       ) {
	      # function argument - return list itself
	      return [ -list => map { $do->($_) } @$expr ];
	    }
	    else {
	      # distribute $array_op over implicit equality
	      return $do->([ $self->{config}{array_op} => @$expr ]);
	    }
	  }
	}
      };
      /HASH/ && do {
	my @k = keys %$expr;
	#######
	if (@k == 1) {
	  my $k = $k[0];
	  # single hashpair
	  if ($is_op->($k)) {
	    $is_op->($k,'infix_binary') && do {
	      puke "Expected LHS for $k" unless $lhs;
	      if (ref $$expr{$k} eq 'ARRAY') {
		# apply binary operator and join with array default op
		return [ $self->{config}{array_op} => map {
		  defined() ?
		    [ $k => $lhs, $do->($_)] :
		    { $self->{config}{ineq_op} => [-is_not_null => $lhs],
		      $self->{config}{implicit_eq_op} => [-is_null => $lhs]
		     }->{$k}
		   } @{$$expr{$k}} ]
	      }
	      elsif (defined $$expr{$k}) {
		return [ $k => $lhs, $do->($$expr{$k},undef,$k) ]; #?
	      }
	      else { # IS (NOT) NULL
		$k eq $self->{config}{ineq_op} && do {
		  return [ -is_not_null => $lhs ];
		};
		$k eq $self->{config}{implicit_eq_op} && do {
		  return [ -is_null => $lhs ];
		};
		puke "Can't handle undef as argument to $k";
	      }
	    };
	    $is_op->($k,'function') && do {
	      return [ $k => $do->($$expr{$k},undef,$k) ];
	    };
	    $is_op->($k,'infix_listarg') && do {
	      return [ $k => $lhs, $do->($$expr{$k},undef,$k) ];
	    };
	    $is_op->($k,'prefix') && do {
	      return [ $k => $do->($$expr{$k}) ];
	    };
	    $is_op->($k,'infix_distributable') && do {
	      if (!ref $$expr{$k} && $lhs) {
		return [ $k => $lhs, $do->($$expr{$k}) ];
	      }
	      elsif ( ref $$expr{$k} eq 'HASH' ) {
		my @ar = %{$$expr{$k}};
		return $do->([$k=>@ar]); #?
	      }
	      elsif ( ref $$expr{$k} eq 'ARRAY') {
		return  $do->([$k => $$expr{$k}]);
	      }
	      else {
		puke "arg type '".ref($$expr{$k})."' not expected for op '$k'";
	      }
	    };
	    $is_op->($k,'predicate') && do {
	      puke "predicate function '$k' requires an length 3 arrayref argument"
		unless ref $$expr{$k} eq 'ARRAY' and @{$$expr{$k}} == 3;
	      return [ $k => [-thing => $$expr{$k}->[0]],
			      $do->($$expr{$k}->[1], undef, $k),
			      $do->($$expr{$k}->[2], undef, $k) ];
	    };
	    $is_op->($k,'reduce') && do {
	      puke "reduce function '$k' requires an length 5 arrayref argument"
		unless ref $$expr{$k} eq 'ARRAY' and @{$$expr{$k}} == 5;
	      return [ $k => [-thing => $$expr{$k}->[0]],
		       $do->($$expr{$k}->[1], undef, $k),
		       [-thing => $$expr{$k}->[2]],
		       $do->($$expr{$k}->[3], undef, $k),
		       $do->($$expr{$k}->[4], undef, $k)];
	    };
	    puke "Operator $k not expected";
	  }
	  elsif (ref($$expr{$k}) && ref($$expr{$k}) ne 'SCALAR') {
	    # $k is an LHS
	    return $do->($$expr{$k}, $k, undef);
	  }
	  else {
	    # implicit equality
	    return defined $$expr{$k} ?
	      [ $self->{config}{implicit_eq_op} => $k,
		$do->($$expr{$k},undef,$self->{config}{implicit_eq_op}) ] :
	      [ -is_null => $k ];
	  }
	}
	#######
	else {
	  # >1 hashpair
	  my @args;
	  for my $k (@k) {
	    # all keys are ops, or none is - otherwise barf
	    if ( $is_op->($k, 'infix_binary') ) {
	      puke "No LHS provided for implicit $$self{config}{hash_op}" unless defined $lhs;
	      push @args, $do->({$k => $$expr{$k}},$lhs);
	    }
	    elsif ( $is_op->($k, 'prefix') || $is_op->($k,'function') ) {
		push @args, [ $k => $do->($$expr{$k},undef, $k) ];
	      }
	      elsif (!$is_op->($k)) {
		push @args, $do->({$k => $$expr{$k}});
	      }
	    else {
	      puke "Problem handling operator '$k'";
	    }
	  }
	  return [ $self->{config}{hash_op} => @args ];
	}
      };
    }
  };
  $ret = $do->($expr);
  return $ret;
}

# peel - recurse $args = [ -op, @args ] to create complete production
sub peel {
  my ($self, $args) = @_;

  if (!defined $args) {
    return '';
  }
  elsif (!ref $args or blessed($args)) { # single literal argument
    return $args;
  }
  elsif (ref $args eq 'ARRAY') {
    return '' unless (@$args);
    my $op = shift @$args;
    puke "'$op' : unknown operator" unless $self->{dispatch}{$op};
    my $expr = $self->_dispatch( $op, [map { $self->peel($_) } @$args] );
    if (grep /\Q$op\E/, @{$type_table{infix_distributable}}) {
      # group
      return "($expr)"
    }
    else {
      return $expr;
    }
  }
  else {
    puke "Can only peel() arrayrefs, scalars or literals";
  }
}

### writers

sub infix_binary {
  my ($self, $op, $args) = @_;
  unless ($op and $args and !ref($op)
	    and ref($args) eq 'ARRAY'){
    puke "arg1 must be scalar, arg2 must be arrayref";
  }
  unless ( @$args == 2 ) {
    puke "For $op, arg2 must have length 2";
  }
  return '('.join(" ", $$args[0], _write_op($op), $$args[1]).')';
}

sub infix_listarg { infix_binary(@_) }

sub infix_distributable {
  my ($self, $op, $args) = @_;
  unless ($op and $args and !ref($op)
	    and ref($args) eq 'ARRAY'){
    puke "arg1 must be scalar, arg2 must be arrayref";
  }
  $op = _write_op($op);
  return join(" $op ", @$args);
}

sub prefix {
  my ($self, $op, $args) = @_;
  unless ($op and $args and !ref($op)
	    and ref($args) eq 'ARRAY'){
    puke "arg1 must be scalar, arg2 must be arrayref";
  }
  unless (@$args == 1) {
    puke "For $op, arg2 must have length 1"
  }
  return _write_op($op)." ".$$args[0];
}

sub postfix {
  my ($self, $op, $args) = @_;
  unless ($op and $args and !ref($op)
	    and ref($args) eq 'ARRAY'){
    puke "arg1 must be scalar, arg2 must be arrayref";
  }
  unless (@$args == 1) {
    puke "For $op, arg2 must have length 1"
  }
  return $$args[0]." "._write_op($op);
}

sub function {
  my ($self, $op, $args) = @_;
  unless ($op and $args and !ref($op)
	    and ref($args) eq 'ARRAY'){
    puke "arg1 must be scalar, arg2 must be arrayref";
  }
  return _write_op($op).'('.join(',',@$args).')';
}

sub predicate {
  my ($self, $op, $args) = @_;
  unless ($op and $args and !ref($op)
	    and ref($args) eq 'ARRAY'){
    puke "arg1 must be scalar, arg2 must be arrayref";
  }
  unless ( @$args == 3 ) {
    puke "For $op, arg2 must have length 3";
  }
  return _write_op($op)."("."$$args[0] IN $$args[1] WHERE $$args[2]".")";
}

sub extract {
  my ($self, $op, $args) = @_;
  unless ($op and $args and !ref($op)
	    and ref($args) eq 'ARRAY'){
    puke "arg1 must be scalar, arg2 must be arrayref";
  }
  unless ( @$args == 3 ) {
    puke "For $op, arg2 must have length 3";
  }
  return _write_op($op)."("."$$args[0] IN $$args[1] | $$args[2]".")";
}

sub reduce {
  my ($self, $op, $args) = @_;
  unless ($op and $args and !ref($op)
	    and ref($args) eq 'ARRAY'){
    puke "arg1 must be scalar, arg2 must be arrayref";
  }
  unless ( @$args == 5 ) {
    puke "For $op, arg2 must have length 5";
  }
  return _write_op($op)."("."$$args[0] = $$args[1], $$args[2] IN $$args[3] | $$args[4]".")";
}

# bind either:
# - pulls out literals, pushes them into {bind_values}, and replaces them
#   with '?' in the produced statement (a la SQL:A), -or-
# - identifies named parameters in the expression and pushes these into
#   {parameters}, leaving them in the produced statement
sub bind { # special
  my ($self, $op, $args) = @_;
  unless ($op and $args and !ref($op)
	    and ref($args) eq 'ARRAY'){
    puke "arg1 must be scalar, arg2 must be arrayref";
  }
  if ($$args[0] =~ $self->{config}{parameter_sigil}) {
    push @{$self->{parameters}}, $$args[0];
  }
  else {
    push @{$self->{bind_values}},
      $self->{config}{anon_placeholder} ? $$args[0] :
      $self->_quote_lit($$args[0]);
  }
  return $self->{config}{anon_placeholder} ?
    $self->{config}{anon_placeholder} :
    $self->_quote_lit($$args[0]);
}

sub list { # special
  my ($self, $op, $args) = @_;
  unless ($op and $args and !ref($op)
	    and ref($args) eq 'ARRAY'){
    puke "arg1 must be scalar, arg2 must be arrayref";
  }
  my ($l,$r) = split '',$self->{config}{list_braces};
  return $l.join(',',@$args).$r;
}

sub thing { # special
  my ($self, $op, $args) = @_;
  return join(' ',@$args);
}

sub _write_op {
  my ($op) = @_;
  $op =~ s/^-//;
  my $c = (caller(1))[3];
  return '' if ($op eq '()');
  return join(' ', map { ($c=~/infix|prefix|postfix/) ? uc $_ : $_ } split /_/,$op);
}

=head1 NAME

Neo4j::Cypher::Abstract::Peeler - Parse Perl structures as expressions

=head1 SYNOPSIS

=head1 DESCRIPTION

C<Neo4j::Cypher::Abstract::Peeler> allows the user to write L<Neo4j
Cypher|https://neo4j.com/docs/developer-manual/current/cypher/> query
language expressions as Perl data structures. The interpretation of
data structures follows L<SQL::Abstract> very closely, but attempts to
be more systematic and general.

C<Peeler> only produces expressions, typically used as arguments to
C<WHERE> clauses. It is integrated into L<Neo4j::Cypher::Abstract>,
which produces full Cypher statements.

Like L<SQL::Abstract>, C<Peeler> translates scalars, scalar refs,
array refs, and hash refs syntactically to create expression
components such as functions and operators. The contents of the
scalars or references are generally operators or the arguments to
operators or functions.

Contents of scalar references are always treated as literals and
inserted into the expression verbatim.

=head2 Expressing Expressions

=over

=item * Functions

Ordinary functions in Cypher are written as the name of the function
preceded by a dash. They can be expressed as follows:

 { -func => $arg }
 [ -func => $arg ]
 \"func($arg)"

 { -sin => $pi/2 }
 # returns sin(<value of $pi>/2)

=item * Infix Operators

Infix operators, like equality (C<=>), inequality (C<E<lt>E<gt>>),
binary operations (C<+,-,*,/>), and certain string operators
(C<-contains>, C<-starts_with>, C<ends_with>) are expressed as follows:

 { $expr1 => { $infix_op => $expr2 } }

 { 'n.name'  => { '<>' => 'Fred' } }
 # returns n.name <> "Fred"

This may seem like overkill, but comes in handy for...

=item * AND and OR

C<Peeler> implements the L<SQL::Abstract> convention that hash refs
represent conditions joined by C<AND> and array refs represent
conditions joined by C<OR>. Key-value pairs and array value pairs are
interpreted as an implicit equalities to be ANDed or ORed.

 { $lhs1 => $rhs1, $lhs2 => $rhs2 }
 { al => 'king', 'eddie' => 'prince', vicky => 'queen' }
 # returns al = "king" AND eddie = "prince" AND vicky = "queen"

 [ $lhs1 => $rhs1, $lhs2 => $rhs2 ]
 [ 'a.name' => 'Fred', 'a.name' => 'Barney']
 # returns a.name = "Fred" OR a.name = "Barney"

A single left-hand side can be "distributed" over a set of conditions,
with corresponding conjunction:

 { zzyxx => [ 'narf', 'boog', 'frelb' ] } # implicit equality, OR
 # returns zzyxx = "narf" OR zzyxx = "boog" OR zzyxx = "frelb"
 { zzyxx => { '<>' =>  'narf', '<>' => 'boog' } } # explicit infix, AND
 # returns zzyxx <> "narf" AND zzyxx <> "boog"
 { zzyxx => [ '<>' =>  'narf', -contains => 'boog' ] } # explicit infix, OR
 # returns zzyxx <> "narf" OR zzyxx CONTAINS "boog"

=item * Expressing null

C<undef> can be used to express NULL mostly as in L<SQL::Abstract> so
that the following are equivalent

 { a.name => { '<>' => undef}, b.name => undef}
 { -is_not_null => 'a.name', -is_null => 'b.name' }
 # returns a.name IS NOT NULL  AND b.name IS NULL

=item * Predicates: -all, -any, -none, -single, -filter

These Cypher functions have the form

 func(variable IN list WHERE predicate)

To render these, provide an array ref of the three arguments in order:

 { -all => ['x', [1,2,3], {'x' => 3}] }
 # returns all(x IN [1,2,3] WHERE x = 3)

=item * List arguments

For cypher expressions that accept lists (arrays in square brackets), use arrayrefs:

 { 'n.name' => { -in => ['fred','wilma','pebbles'] }}
 # returns n.name IN ['fred','wilma','pebbles']

=back

=head2 Parameters and Bind Values

Cypher parameters (which use the '$' sigil) may be included in
expressions (with the dollar sign appropriately escaped). These are
collected during parsing and can be reported in order with the the
C<parameters()> method.

L<SQL::Abstract> automatically collects literal values and replaces
them with anonymous placeholders (C<?>), returning an array of values
for binding in L<DBI>. C<Peeler> will collect values and report them
with the C<bind_values()> method. If the config key
C<anon_placeholder> is set:

 $peeler->{config}{anon_placeholder} = '?'

then C<Peeler> will also do the replacement in the final expression
production like L<SQL::Abstract>.

The real reason to pay attention to literal values is to be able to
appropriately quote them in the final production. When
C<anon_placeholder> is not set (default), then an attempt is made to
correctly quote string values and such.

=head1 GUTS

 TBD

=head2 The config hash

The C<Peeler> object property C<{config}> is a hashref containing
various defaults to make Peeler output sound like Cypher. One could
customize it to make output sound like SQL (someday).

Keys/values are as follows:

 bind => 1,
 anon_placeholder => undef, # '?',
 hash_op => '-and',
 array_op => '-or',
 list_braces => '[]',
 ineq_op => '<>',
 implicit_eq_op => '=',
 quote_lit => "'",
 esc_quote_lit => "\\",
 parameter_sigil => qw/^([:$?])|({[^}]+}$)/,
 quote_fld => undef,
 safe_identifier => qw/[a-zA-Z_.]+/

=head1 METHODS

=over

=item express()

Canonize, then peel. Returns scalar string (the expression).

=item canonize()

Render SQL:A-like expression into a canonical lisp-like array
tree. Returns an arrayref.

=item peel()

Render a canonical tree as a Cypher string expression. Returns scalar
string.

=item parameters()

Get a list in order of all named parameters.

=item bind_values()

Get a list of bind values in order that were replaced by the anonymous
placeholder.

=back

=head1 SEE ALSO

L<Neo4j::Cypher::Abstract>, L<SQL::Abstract>.

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 LICENSE

This software is provided for use under the terms of Perl itself.

=head1 COPYRIGHT

 (c) 2017 Mark A. Jensen

=cut

1;
