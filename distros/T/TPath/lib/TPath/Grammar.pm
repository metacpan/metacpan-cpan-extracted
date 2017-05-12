# ABSTRACT: parses TPath expressions into ASTs

package TPath::Grammar;
$TPath::Grammar::VERSION = '1.007';
use v5.10;
use strict;
use warnings;
no if $] >= 5.018, warnings => "experimental";

use POSIX qw(acos asin atan ceil floor log10 tan);
use Math::Trig qw(pi);
use Scalar::Util qw(looks_like_number);

use parent qw(Exporter);

our @EXPORT_OK = qw(parse %AXES %FUNCTIONS %MATH_CONSTANTS);


our %AXES = map { $_ => 1 } qw(
  adjacent
  ancestor
  ancestor-or-self
  child
  descendant
  descendant-or-self
  following
  following-sibling
  leaf
  parent
  preceding
  preceding-sibling
  previous
  self
  sibling
  sibling-or-self
);

# single-argument mathematical functions
our %FUNCTIONS = (
    abs   => sub { abs $_[0] },
    acos  => \&acos,
    asin  => \&asin,
    atan  => \&atan,
    ceil  => \&ceil,
    cos   => sub { cos $_[0] },
    exp   => sub { exp $_[0] },
    floor => \&floor,
    int   => sub { int $_[0] },
    log   => sub { log $_[0] },
    log10 => \&log10,
    sin   => sub { sin $_[0] },
    sqrt  => sub { sqrt $_[0] },
    tan   => sub { tan $_[0] },
);

our %MATH_CONSTANTS = (
    pi => pi,
    e  => exp 1,
);

# map from operators to their properties;
# [<precedence>, <commutative>, <left-associative>, <dual>]
# not sure if "dual" is the right term; it's the operator one can use to reduce
# the right operands with a non-commutative operator
our %MATH_OPERATORS = (
    '+'  => [ 3, 1, 1 ],
    '-'  => [ 3, 0, 1, '+' ],
    '*'  => [ 2, 1, 1 ],
    '/'  => [ 2, 0, 1, '*' ],
    '**' => [ 1, 0, 1, '*' ],
    '%'  => [ 2, 0, 0 ],
);

# sort these into a list for use in reducing complex mathematical expressions
my @math_ops =
  map { my @ar = @{ $MATH_OPERATORS{$_} }; $ar[0] = $_; \@ar }
  sort {
         $MATH_OPERATORS{$a}[0] <=> $MATH_OPERATORS{$b}[0]
      || $MATH_OPERATORS{$b}[1] <=> $MATH_OPERATORS{$a}[1]
      || $MATH_OPERATORS{$b}[2] <=> $MATH_OPERATORS{$a}[2]
  }
  keys %MATH_OPERATORS;

our ( $offset, $quantifiable );
our $path_grammar = do {
    our $buffer;
    use Regexp::Grammars;
    qr{
       <timeout: 10>
    
    \A <.ws> <treepath> <.ws> \Z
    
       <rule: treepath> <[path]> (?: \| <[path]> )*
    
       <token: path> (?![\@'"]) <[segment]> (?: (?= / | \( <.ws> / ) <[segment]> )*
    
       <token: segment> (?: <separator>? <step> | <cs> ) <.ws>
       
       <token: quantifier> (?: <require: (?{$quantifiable}) > [?+*] | <enum> ) <.cp>
       
       <rule: enum> 
          [{] <start=(\d*+)> (?: , <end=(\d*+)> )? [}] 
          <require: (?{length $MATCH{start} or length $MATCH{end}})>
       
       <rule: grouped_step> 
          \( <treepath> \) 
          (?:
             (?: <.ws> <[predicate]> )+
             | 
             (?{local $quantifiable = 1}) <quantifier>
          )?
    
       <token: id>
          :id\( ( (?>[^\)\\]|\\.)++ ) \)
          (?{ $MATCH=clean_escapes($^N) }) <.cp>
    
       <token: cs>
           <separator>? <step> (?{local $quantifiable = 1}) <quantifier>
          | <grouped_step>
    
       <token: separator> \/[\/>]?+ <.cp>
    
       <token: step> <full> (?: <.ws> <[predicate]> )* | <abbreviated>
    
       <token: full> <axis>? <forward> | (?<=(?<!/)/) <previous=(:p)> <.cp>
    
       <token: axis> 
          (?<!/[/>]) (<%AXES>) ::
          (?{ $MATCH = $^N }) <.cp>
    
       <token: abbreviated> (?<!/[/>]) (?: \.{1,2}+ | <id> | :root ) <.cp>
    
       <token: forward> 
           <wildcard> | <complement=(\^)>? (?: <specific> | <pattern> | <attribute> )
    
       <token: wildcard> <require: (?{!$quantifiable}) > \* <.cp>
       
       <token: specific>
          <name>
          (?{ $MATCH = $MATCH{name} }) <.cp>
    
       <token: pattern>
          (~(?>[^~]|~~)++~)
          (?{ $MATCH = clean_pattern($^N) }) <.cp>
    
       <token: aname>
          @ (?: <name> | : <name> (?{ $MATCH{autoloaded} = 1 }) )
       
       <token: name>
          ((?>\\.|[\p{L}\$_])(?>[\p{L}\$\p{N}_]|[-.:](?=[\p{L}_\$\p{N}])|\\.)*+)  (?{ $MATCH = clean_escapes($^N ) })
          | <literal> (?{ $MATCH = $MATCH{literal} })
          | (<.qname>) (?{ $MATCH = clean_escapes( substr $^N, 2, length($^N) -3 ) })
       
       <token: qname> 
          : <.qq> <.cp> 
     
       <token: qq> 
          ([!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~])   # [:punct:] excluding backslash
          (?{ local $buffer = end_punct($^N) })
          (?:
             [^[:punct:]]
             |
             ([[:punct:]]) (?(?{ $^N eq $buffer or $^N eq '\\' })(?!))
             |
             \\ .
          )++
          ([!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~])
          <require: (?{ $^N eq $buffer })>

       <rule: attribute> <aname> <args>?
    
       <rule: args> \( <[arg]> (?: , <[arg]> )* \) <.cp>
    
       <token: arg>
           <v=literal> | <v=num> | <concat> | <attribute> | <treepath> | <attribute_test> | <condition>
       
       <rule: concat> # string concatenation
           <[carg]> (?: ~ <[carg]>)+
       
       <token: carg>
           <v=literal> | <v=num> | <attribute> | <treepath> | <math>
    
       <token: num> <.signed_int> | <.float>
    
       <token: signed_int> [+-]?+ <.int> <.cp>
    
       <token: float> [+-]?+ <.int>? \.\d++ (?: [Ee][+-]?+ <.int> )?+ <.cp>
    
       <token: literal>
          ((?> <.squote> | <.dquote> ))
          (?{ $MATCH = clean_literal($^N) })
    
       <token: squote> ' (?>[^'\\]|\\.)*+ ' <.cp>
    
       <token: dquote> " (?>[^"\\]|\\.)*+ " <.cp>
    
       <rule: predicate>
          \[ (?: <idx=signed_int> | <condition> ) \] <.cp>
    
       <token: int> \b(?:0|[1-9][0-9]*+)\b <.cp>
    
       <rule: condition> 
          <[item=not]>? <[item]> (?: <[item=operator]> <[item=not]>? <[item]> )*

       <token: not>
          ( 
             (?: ! | (?<=[\s\[(]) not (?=\s) ) 
             (?: \s*+ (?: ! | (?<=\s) not (?=\s) ) )*+ 
          )
          (?{$MATCH = clean_not($^N)}) <.cp>
       
       <token: operator>
          (?: <.or> | <.xor> | <.and> )
          (?{$MATCH = clean_operator($^N)})
       
       <token: xor> (?: ; | (?<=\s) one (?=\s) ) <.cp>
           
       <token: and> (?: & | (?<=\s) and (?=\s) ) <.cp>
           
       <token: or> (?: \|{2} | (?<=\s) or (?=\s) ) <.cp>
    
       <token: term> <attribute> | <attribute_test> | <treepath>
    
       <rule: attribute_test>
          <[value]> (?: <cmp=([!=]~)> <[value=regex]> | <cmp> <[value]> )
       
       <token: regex>
          ( / (?:[^/\\]|\\.)++ /(?!=\w|:) )
          (?{ $MATCH = clean_regex($^N) })
          <.cp>
          |
          :m ( <.qq> ) 
          (?{ local $buffer = $^N }) <.cp>
          ((?:[msix]+\b)?) <require: (?{ mods_test($^N) })>
          (?{ $MATCH = clean_mregex($buffer, $^N) }) <.cp>
    
       <token: cmp> (?: [<>=]=?+ | ![=~] | =~ | =?\|= | =\| ) <.cp>
    
       <token: value> <v=literal> | <v=num> | <concat> | <attribute> | <treepath> | <math>
       
       <rule: math> <function> | <[item=operand]> (?: <.ws> <[item=mop]> <[item=operand]> )*
       
       <token: function> :? <f=%FUNCTIONS> \( <.ws> <arg=math> <.ws> \) <.cp>
       
       <token: mop> :? ( <%MATH_OPERATORS> ) (?{ $MATCH = $^N }) <.cp>
       
       <token: operand> <num> | <minus=(-)>? (?: <mconst> | <attribute> | <treepath> | <mgroup> | <function> )
       
       <token: mconst> : ( <%MATH_CONSTANTS> ) (?{ $MATCH = $^N }) <.cp>
       
       <rule: mgroup> \( <math> \) <.cp>
    
       <rule: group> \( <condition> \) <.cp>
    
       <token: item> <term> | <group>
          
       <token: ws> (?: \s*+ (?: \#.*? $ )?+ )*+ <.cp>
       
       <token: cp> # "checkpoint"
          (?{ $offset = $INDEX if $INDEX > $offset })
    }xms;
};


sub parse {
    local $offset = 0;
    my ($expr) = @_;
    if ( $expr =~ $path_grammar ) {
        my $ref = \%/;
        normalize_math($ref);
        normalize_compounds($ref);
        complement_to_boolean($ref);
        if ( contains_condition($ref) ) {
            normalize_parens($ref);
            operator_precedence($ref);
            merge_conditions($ref);
            fix_predicates($ref);
        }
        cull_predicates($ref);
        optimize($ref);
        return $ref;
    }
    else {
        die "could not parse '$expr' as a TPath expression; "
          . error_message( $expr, $offset );
    }
}

# remove necessarily true predicates; throw errors in case of
# necessarily false predicates
sub cull_predicates {
    my $ref = shift;
    for ( ref $ref ) {
        when ('ARRAY') { cull_predicates($_) for @$ref }
        when ('HASH') {
            cull_predicates($_) for values %$ref;
            my $predicates = $ref->{predicate};
            if ($predicates) {
                for ( my $i = $#$predicates ; $i >= 0 ; $i-- ) {
                    my $predicate = $predicates->[$i];
                    my $at        = $predicate->{attribute_test};
                    if ( $at && is_deeply( @{ $at->{value} } ) ) {
                        my $op = $at->{cmp};
                        if ( $op =~ /(?<!!)=$/ ) {
                            splice @$predicates, $i;    # always true
                        }
                        else {
                            die 'bad predicate: ['
                              . $predicate->{''}
                              . ']';                    # always false
                        }
                    }
                }
            }
            elsif (exists $ref->{step}
                && exists $ref->{step}{predicate}
                && @{ $ref->{step}{predicate} } == 0 )
            {
                delete $ref->{step}{predicate};
            }
        }
    }
}

# deep equality test used in culling predicates
sub is_deeply {
    my ( $r1, $r2 ) = @_;
    my $t1 = ref $r1;
    my $t2 = ref $r2;
    return if $t1 xor $t2;
    if ($t1) {
        return unless $t1 eq $t2;
        for ($t1) {
            when ('ARRAY') {
                my @ar = @$r1;
                return unless @ar == @$r2;
                for my $i ( 0 .. $#ar ) {
                    return unless is_deeply( $ar[$i], $r2->[$i] );
                }
                return 1;
            }
            when ('HASH') {
                my @ar = keys %$r1;
                return unless @ar == keys %$r2;
                for my $k (@ar) {
                    return
                      unless exists $r2->{$k}
                      and is_deeply( $r1->{$k}, $r2->{$k} );
                }
                return 1;
            }
            default { die "logic failure" }
        }
    }
    else {
        return $r1 == $r2
          if looks_like_number($r1) && looks_like_number($r2);
        return $r1 eq $r2;
    }
}

# normalize mathematical expressions
sub normalize_math {
    my $ref = shift;
    if ( contains_math($ref) ) {
        normalize_mconst($ref);
        fix_functions($ref);
        reduce_arithmetic($ref);
        promote_operators($ref);
        collapse_math($ref);
    }
}

# fix { math => { operator=> undef, item=>[ { math => ... } ] } }
sub collapse_math {
    my $ref = shift;
    for ( ref $ref ) {
        when ('ARRAY') { collapse_math($_) for @$ref }
        when ('HASH') {
            collapse_math($_) for values %$ref;
            if ( my $m = $ref->{math} ) {
                unless ( $m->{operator} ) {
                    delete $ref->{$_} for keys %$ref;
                    $m = $m->{item}[0];
                    for ( my ( $k, $v ) = each %$m ) {
                        $ref->{$k} = $v;
                    }
                }
            }
        }
    }
}

sub fix_functions {
    my $ref = shift;
    for ( ref $ref ) {
        when ('ARRAY') { fix_functions($_) for @$ref }
        when ('HASH') {
            fix_functions($_) for values %$ref;
            if ( $ref->{function} ) {
                my @items = @{ $ref->{function}{arg}{item} };
                if ( @items == 1 ) {
                    $ref->{function}{arg} =
                      $items[0];
                }
                else {
                    $ref->{function}{arg} = { math => { item => \@items } };
                }
            }
        }
    }
}

# converts operators from infix to prefix
sub promote_operators {
    my $ref = shift;
    for ( ref $ref ) {
        when ('ARRAY') { promote_operators($_) for @$ref }
        when ('HASH') {
            promote_operators($_) for values %$ref;
            if ( exists $ref->{math} ) {
                if ( exists $ref->{math}{item} ) {
                    $ref->{math}{operator} = $ref->{math}{item}[1];
                    $ref->{math}{item} =
                      [ grep { ref $_ } @{ $ref->{math}{item} } ];
                }
                elsif ( exists $ref->{math}{function} ) {
                    $ref->{function} = delete $ref->{math}{function};
                    delete $ref->{math};
                }
            }
        }
    }
}

# apply math to constant operands
sub reduce_arithmetic {
    my $ref = shift;
    for ( ref $ref ) {
        when ('HASH') {

            # depth first
            reduce_arithmetic($_) for values %$ref;
            if ( exists $ref->{function} ) {
                my $num = $ref->{function}{arg}{num};
                if ( defined $num ) {
                    $num = $FUNCTIONS{ $ref->{function}{f} }->($num);
                    delete $ref->{function};
                    $ref->{num} = $num;
                }
            }
            elsif ( exists $ref->{attribute_test} ) {
                my $values = $ref->{attribute_test}{value};
                for my $i ( 0 .. $#$values ) {
                    my $value = $values->[$i];
                    if (   exists $value->{math}
                        && exists $value->{math}{num} )
                    {
                        $value->{v} = $value->{math}{num};
                        delete $value->{math};
                    }
                    elsif ( exists $value->{num} ) {
                        $value->{v} = $value->{num};
                        delete $value->{num};
                    }
                }
            }
            elsif ( exists $ref->{math} || exists $ref->{mgroup} ) {
                my $key = exists $ref->{math} ? 'math' : 'mgroup';
                my $items = $ref->{$key}{item};
                if ( defined $items ) {
                    for ( scalar @$items ) {
                        when (1) {
                            if ( exists $items->[0]{num} ) {
                                $ref->{num} = $items->[0]{num};
                                delete $ref->{$key};
                            }
                        }
                        when (3) {
                            if (   exists $items->[0]{num}
                                && exists $items->[2]{num} )
                            {
                                my ( $l, $op, $r ) = @$items;
                                my $num = eval $l->{num} . $op . $r->{num};
                                $ref->{num} = $num;
                                delete $ref->{$key};
                            }
                            else {
                                my $operator = $items->[1];
                                if ( $MATH_OPERATORS{$operator}[1] )
                                {    # commutative?
                                    my ( $variables, $constants ) =
                                      sort_vals(
                                        grep_nums( $items, [ 0, 2 ] ) );
                                    splice @$items, 0, 3,
                                      {
                                        math => {
                                            item => [
                                                interleave(
                                                    $operator, @$constants,
                                                    @$variables,
                                                )
                                            ]
                                        }
                                      };
                                }
                            }
                        }
                        default {
                            for my $op_spec (@math_ops) {
                                if ( @$items == 1 ) {
                                    delete $ref->{$_} for keys %$ref;
                                    $ref->{$_} = $items->[0]{$_}
                                      for keys %{ $items->[0] };
                                    last;
                                }
                                my ( $operator, $commutative,
                                    $left_associative, $dual )
                                  = @$op_spec;
                                if ($left_associative) {    # left-associative
                                    my @ranges =
                                      collect_ranges( $items, $operator );
                                    if (@ranges) {
                                        if ($commutative) {
                                            for my $range ( reverse @ranges ) {
                                                my ( $variables, $constants ) =
                                                  sort_vals(
                                                    grep_nums( $items, $range )
                                                  );
                                                my ( $start, $length ) = (
                                                    $range->[0],
                                                    $range->[1] -
                                                      $range->[0] + 1
                                                );
                                                if ( @$constants > 1 ) {
                                                    my @nums =
                                                      map { $_->{num} }
                                                      @$constants;
                                                    my $expr =
                                                      join $operator,
                                                      @nums;
                                                    my $v = eval $expr;
                                                    if (@$variables) {
                                                        splice @$items,
                                                          $start, $length,
                                                          {
                                                            math => {
                                                                item => [
                                                                    interleave(
                                                                        {
                                                                            num =>
                                                                              $v
                                                                        },
                                                                        @$variables,
                                                                        $operator,
                                                                    )
                                                                ]
                                                            }
                                                          };
                                                    }
                                                    else {
                                                        splice @$items,
                                                          $start,
                                                          $length,
                                                          { num => $v };
                                                    }
                                                }
                                                else {
                                                    splice @$items, $start,
                                                      $length,
                                                      {
                                                        math => {
                                                            item => [
                                                                interleave(
                                                                    $operator,
                                                                    @$constants,
                                                                    @$variables,
                                                                )
                                                            ]
                                                        }
                                                      };
                                                }
                                            }
                                        }
                                        else {    # non-commutative
                                            for my $range ( reverse @ranges ) {
                                                my ( $start, $length ) = (
                                                    $range->[0],
                                                    $range->[1] -
                                                      $range->[0] + 1
                                                );
                                                my ( $left, @nums ) =
                                                  grep_nums( $items, $range );
                                                my ( $variables, $constants ) =
                                                  sort_vals(@nums);
                                                if ( @$constants > 1 ) {
                                                    my @nums =
                                                      map { $_->{num} }
                                                      @$constants;
                                                    my $expr = join $dual,
                                                      @nums;
                                                    my $v = eval $expr;
                                                    if (@$variables) {
                                                        splice @$items,
                                                          $start, $length,
                                                          {
                                                            math => {
                                                                item => [
                                                                    interleave(
                                                                        $operator,
                                                                        $left,
                                                                        {
                                                                            num =>
                                                                              $v
                                                                        },
                                                                        @$variables,
                                                                    )
                                                                ]
                                                            }
                                                          };
                                                    }
                                                    elsif (
                                                        exists $left->{num} )
                                                    {
                                                        splice @$items,
                                                          $start,
                                                          $length,
                                                          { num =>
                                                              eval $left->{num}
                                                              . $operator
                                                              . $v };
                                                    }
                                                    else {
                                                        splice @$items,
                                                          $start, $length,
                                                          {
                                                            math => {
                                                                item => [
                                                                    interleave(
                                                                        $operator,
                                                                        $left,
                                                                        {
                                                                            num =>
                                                                              $v
                                                                        }
                                                                    )
                                                                ]
                                                            }
                                                          };
                                                    }
                                                }
                                                elsif (@$constants == 1
                                                    && !@$variables
                                                    && exists $left->{num} )
                                                {
                                                    my $v =
                                                        eval $left->{num}
                                                      . $operator
                                                      . $constants->[0]{num};
                                                    splice @$items, $start,
                                                      $length,
                                                      { num => $v };
                                                }
                                                else {
                                                    splice @$items, $start,
                                                      $length,
                                                      {
                                                        math => {
                                                            item => [
                                                                interleave(
                                                                    $operator,
                                                                    $left,
                                                                    @$constants,
                                                                    @$variables,
                                                                )
                                                            ]
                                                        }
                                                      };
                                                }
                                            }
                                        }
                                    }
                                }
                                else {    # right-associative
                                    for (
                                        my $i = $#$items - 1 ;
                                        $i > 0 ;
                                        $i -= 2
                                      )
                                    {
                                        my $op = $items->[$i];
                                        if (   $op eq $operator
                                            && exists $items->[ $i - 1 ]{num}
                                            && exists $items->[ $i + 1 ]{num} )
                                        {
                                            splice @$items, $i - 1, 3,
                                              { num => eval $items->[ $i - 1 ]
                                                  . $op
                                                  . $items->[ $i + 1 ] };
                                        }
                                        else {
                                            last;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                elsif ( exists $ref->{$key}{num} ) {
                    $ref->{num} = $ref->{$key}{num};
                    delete $ref->{$key};
                }
            }
        }
        when ('ARRAY') { reduce_arithmetic($_) for @$ref }
    }
}

# like join but it doesn't stringify the results
sub interleave {
    my ( $op, @items ) = @_;
    my @ar = ( $items[0] );
    push @ar, $op, $_ for @items[ 1 .. $#items ];
    return @ar;
}

# sorts items conjoined by some arithmetic operator such that variables sort before constants
sub sort_vals {
    my ( $variables, $constants ) = ( [], [] );
    push @{ exists $_->{num} ? $constants : $variables }, $_ for @_;
    return $variables, $constants;
}

# pulls out the non-operators
sub grep_nums {
    my ( $items, $range ) = @_;
    grep { ref $_ } @$items[ $range->[0] .. $range->[1] ];
}

# looks for ranges of mathematical expressions all with the same operator
sub collect_ranges {
    my ( $items, $op ) = @_;
    my ( @ranges, $start );
    my ( $i,      $lim );
    for ( ( $i, $lim ) = ( 1, $#$items - 1 ) ; $i <= $lim ; $i += 2 ) {
        my $op2 = $items->[$i];
        if ( $op2 eq $op ) {
            $start = $i - 1 if !defined $start;
        }
        elsif ( defined $start ) {
            push @ranges, [ $start, $i - 1 ];
            undef $start;
        }
    }
    push @ranges, [ $start, $i - 1 ] if defined $start;
    return @ranges;
}

# checks to see whether there is any math in the expression
sub contains_math {
    my $ref = shift;
    for ( ref $ref ) {
        when ('HASH') {
            return 1 if exists $ref->{math};
            for my $v ( values %$ref ) {
                return 1 if contains_math($v);
            }
        }
        when ('ARRAY') {
            for my $v (@$ref) {
                return 1 if contains_math($v);
            }
        }
    }
    return 0;
}

# convert mathematical constants to values
sub normalize_mconst {
    my $ref = shift;
    for ( ref $ref ) {
        when ('HASH') {
            if ( exists $ref->{mconst} ) {
                my $num = $MATH_CONSTANTS{ $ref->{mconst} };
                $ref->{num} = exists $ref->{minus} ? -$num : $num;
                delete $ref->{mconst};
                delete $ref->{minus};
            }
            else {
                normalize_mconst($_) for values %$ref;
            }
        }
        when ('ARRAY') { normalize_mconst($_) for @$ref }
    }
}

# constructs an error message indicating the parsable portion of the expression
sub error_message {
    my ( $expr, $offset ) = @_;
    my $start = $offset - 20;
    $start = 0 if $start < 0;
    my $prefix = substr $expr, 0, $offset;
    my $end = $offset + 20;
    $end = length $expr if length $expr < $end;
    my $suffix = substr $expr, $offset, $end - $offset;
    my $error = 'matching failed at position marked by <HERE>: ';
    $error .= '...'   if $start > 0;
    $error .= $prefix if $prefix;
    $error .= '<HERE>';
    $error .= $suffix if $suffix;
    $error .= '...'   if $end < length $expr;
    return $error;
}

# convert (/foo) to /foo and (/foo)? to /foo?
sub normalize_compounds {
    my $ref = shift;
    for ( ref $ref ) {
        when ('HASH') {

            # depth first
            normalize_compounds($_) for values %$ref;
            my $cs = $ref->{cs};
            if ($cs) {
                normalize_enums($cs);
                my $gs = $cs->{grouped_step};
                if (   $gs
                    && @{ $gs->{treepath}{path} } == 1
                    && @{ $gs->{treepath}{path}[0]{segment} } == 1
                    && !$gs->{predicate} )
                {
                    my $quantifier = $gs->{quantifier};
                    my $step       = $gs->{treepath}{path}[0]{segment}[0];
                    $step->{quantifier} = $quantifier if $quantifier;
                    $ref->{cs} = $step;
                }
            }
        }
        when ('ARRAY') {

            # depth first
            normalize_compounds($_) for @$ref;

            my $among_steps;
            for my $i ( 0 .. $#$ref ) {
                my $v = $ref->[$i];
                last unless $among_steps // ref $v;
                my $cs = $v->{cs};
                $among_steps //= $cs // 0 || $v->{step} // 0;
                last unless $among_steps;
                if ($cs) {
                    if ( $cs->{step} ) {
                        if ( !$cs->{quantifier} ) {
                            splice @$ref, $i, 1, $cs;
                        }
                        elsif ( $cs->{quantifier} eq 'vacuous' ) {
                            delete $cs->{quantifier};
                            splice @$ref, $i, 1, $cs;
                        }
                    }
                    elsif (
                        ( $cs->{grouped_step}{quantifier} // '' ) eq 'vacuous' )
                    {
                        my $path = $cs->{grouped_step}{treepath}{path};
                        if ( @$path == 1 ) {
                            splice @$ref, $i, 1, @{ $path->[0]{segment} };
                        }
                    }
                }
            }
        }
    }
}

# normalizes enumerated quantifiers
sub normalize_enums {
    my $cs         = shift;
    my $is_grouped = exists $cs->{grouped_step};
    my $q =
        $is_grouped
      ? $cs->{grouped_step}{quantifier}
      : $cs->{quantifier};
    return unless $q && ref $q;
    my $enum          = $q->{enum};
    my $start_defined = $enum->{start} ne '';
    my $start         = $enum->{start} ||= 0;
    my $end;

    if ( exists $enum->{end} ) {
        $end = $enum->{end} || 0;
    }
    else {
        $end = $start;
    }
    if ( $end == 1 ) {
        if ( $start == 1 ) {
            if ($is_grouped) {
                $cs->{grouped_step}{quantifier} = 'vacuous';
            }
            else {
                $cs->{quantifier} = 'vacuous';
            }
            return;
        }
        if ( $start == 0 ) {
            if ($is_grouped) {
                $cs->{grouped_step}{quantifier} = '?';
            }
            else {
                $cs->{quantifier} = '?';
            }
            return;
        }
    }
    elsif ( $start == 1 && $end == 0 ) {
        if ($is_grouped) {
            $cs->{grouped_step}{quantifier} = '+';
        }
        else {
            $cs->{quantifier} = '+';
        }
        return;
    }
    elsif ($start_defined
        && $start == 0
        && ( $enum->{end} // 'bad' ) eq '' )
    {
        if ($is_grouped) {
            $cs->{grouped_step}{quantifier} = '*';
        }
        else {
            $cs->{quantifier} = '*';
        }
        return;
    }
    die 'empty {x,y} quantifier in ' . $cs->{''} unless $start || $end;
    die 'in {x,y} quantifier end is less than start in ' . $cs->{''}
      if $start > $end && ( $enum->{end} // '' ) ne '';
    $enum->{end} = $end;
}

# converts complement => '^' to complement => 1 simply to make AST function clearer
sub complement_to_boolean {
    my $ref = shift;
    for ( ref $ref ) {
        when ('HASH') {
            for my $k ( keys %$ref ) {
                if ( $k eq 'complement' ) { $ref->{$k} &&= 1 }
                else { complement_to_boolean( $ref->{$k} ) }
            }
        }
        when ('ARRAY') { complement_to_boolean($_) for @$ref }
    }
}

# remove no-op steps etc.
sub optimize {
    my $ref = shift;
    clean_no_op($ref);
    clean_context($ref);
}

sub clean_context {
    my $ref = shift;
    for ( ref $ref ) {
        when ('ARRAY') { clean_context($_) for @$ref }
        when ('HASH') {
            clean_context($_) for values %$ref;
            delete $ref->{''};
        }
    }
}

# remove . and /. steps
sub clean_no_op {
    my $ref = shift;
    for ( ref $ref ) {
        when ('HASH') {
            my $paths = $ref->{path};
            for my $path ( @{ $paths // [] } ) {
                my @segments = @{ $path->{segment} };
                my @cleaned;
                for my $i ( 1 .. $#segments ) {
                    my $step = $segments[$i];
                    push @cleaned, $step unless find_dot($step);
                }
                if (@cleaned) {
                    my $step = $segments[0];
                    if ( find_dot($step) ) {
                        my $sep  = $step->{separator};
                        my $next = $cleaned[0];
                        my $nsep = $next->{separator};
                        if ($sep) {
                            unshift @cleaned, $step
                              unless $nsep eq '/' && find_axis($next);
                        }
                        else {
                            if ( $nsep eq '/' ) {
                                delete $next->{separator};
                            }
                            else {
                                unshift @cleaned, $step;
                            }
                        }
                    }
                    else {
                        unshift @cleaned, $step;
                    }
                }
                else {
                    @cleaned = @segments;
                }
                $path->{segment} = \@cleaned;
            }
            clean_no_op($_) for values %$ref;
        }
        when ('ARRAY') {
            clean_no_op($_) for @$ref;
        }
    }
}

# returns the axis if any; prevents reification of hash keys
sub find_axis {
    my $next = shift;
    my $step = $next->{step};
    return unless $step;
    my $full = $step->{step};
    return unless $full;
    return $full->{axis};
}

# finds dot, if any; prevents reification of hash keys
sub find_dot {
    my $step = shift;
    exists $step->{step}
      && ( $step->{step}{abbreviated} // '' ) eq '.';
}

# remove unnecessary levels in predicate trees
sub fix_predicates {
    my $ref  = shift;
    my $type = ref $ref;
    for ($type) {
        when ('HASH') {
            while ( my ( $k, $v ) = each %$ref ) {
                if ( $k eq 'predicate' ) {
                    for my $i ( 0 .. $#$v ) {
                        my $item = $v->[$i];
                        next if exists $item->{idx};
                        if ( ref $item->{condition} eq 'ARRAY' ) {
                            $item = $item->{condition}[0];
                            splice @$v, $i, 1, $item;
                        }
                        fix_predicates($item);
                    }
                }
                else {
                    fix_predicates($v);
                }
            }
        }
        when ('ARRAY') { fix_predicates($_) for @$ref }
    }
}

# merge nested conditions with the same operator into containing conditions
sub merge_conditions {
    my $ref  = shift;
    my $type = ref $ref;
    return $ref unless $type;
    for ($type) {
        when ('HASH') {
            while ( my ( $k, $v ) = each %$ref ) {
                if ( $k eq 'condition' ) {
                    if ( !exists $v->{args} ) {
                        merge_conditions($_) for values %$v;
                        next;
                    }

                    # depth first
                    merge_conditions($_) for @{ $v->{args} };
                    my $op = $v->{operator};
                    my @args;
                    for my $a ( @{ $v->{args} } ) {
                        my $condition = $a->{condition};
                        if ( defined $condition ) {
                            my $o = $condition->{operator};
                            if ( defined $o ) {
                                if ( $o eq $op ) {
                                    push @args, @{ $condition->{args} };
                                }
                                else {
                                    push @args, $a;
                                }
                            }
                            else {
                                push @args, $condition;
                            }
                        }
                        else {
                            push @args, $a;
                        }
                    }
                    $v->{args} = \@args;
                }
                else {
                    merge_conditions($v);
                }
            }
        }
        when ('ARRAY') { merge_conditions($_) for @$ref }
        default { die "unexpected type $type" }
    }
}

# group operators and arguments according to operator precedence ! > & > ; > ||
sub operator_precedence {
    my $ref  = shift;
    my $type = ref $ref;
    return $ref unless $type;
    for ($type) {
        when ('HASH') {
            while ( my ( $k, $v ) = each %$ref ) {
                if ( $k eq 'condition' && ref $v eq 'ARRAY' ) {
                    my @ar = @$v;

                    # normalize ! strings
                    @ar = grep { $_ } map {
                        if ( !ref $_ && /^!++$/ ) {
                            ( my $s = $_ ) =~ s/..//g;
                            $s;
                        }
                        else { $_ }
                    } @ar;
                    $ref->{$k} = \@ar if @$v != @ar;

                    # depth first
                    operator_precedence($_) for @ar;
                    return $ref if @ar == 1;

                    # build binary logical operation tree
                  OUTER: while ( @ar > 1 ) {
                        for my $op (qw(! & ; ||)) {
                            for my $i ( 0 .. $#ar ) {
                                my $item = $ar[$i];
                                next if ref $item;
                                if ( $item eq $op ) {
                                    if ( $op eq '!' ) {
                                        splice @ar, $i, 2,
                                          {
                                            condition => {
                                                operator => '!',
                                                args     => [ $ar[ $i + 1 ] ]
                                            }
                                          };
                                    }
                                    else {
                                        splice @ar, $i - 1, 3,
                                          {
                                            condition => {
                                                operator => $op,
                                                args     => [
                                                    $ar[ $i - 1 ],
                                                    $ar[ $i + 1 ]
                                                ]
                                            }
                                          };
                                    }
                                    next OUTER;
                                }
                            }
                        }
                    }

                    # replace condition with logical operation tree
                    $ref->{condition} = $ar[0]{condition};
                }
                else {
                    operator_precedence($v);
                }
            }
        }
        when ('ARRAY') { operator_precedence($_) for @$ref }
        default { die "unexpected type $type" }
    }
    return $ref;
}

# looks for structures requiring normalization
sub contains_condition {
    my $ref  = shift;
    my $type = ref $ref;
    return 0 unless $type;
    if ( $type eq 'HASH' ) {
        while ( my ( $k, $v ) = each %$ref ) {
            return 1 if $k eq 'condition' || contains_condition($v);
        }
        return 0;
    }
    for my $v (@$ref) {
        return 1 if contains_condition($v);
    }
    return 0;
}

# removes redundant parentheses and simplifies condition elements somewhat
sub normalize_parens {
    my $ref  = shift;
    my $type = ref $ref;
    return $ref unless $type;
    for ($type) {
        when ('ARRAY') {
            normalize_parens($_) for @$ref;
        }
        when ('HASH') {
            for my $name ( keys %$ref ) {
                my $value = $ref->{$name};
                if ( $name eq 'condition' ) {
                    my @ar = @{ $value->{item} };
                    for my $i ( 0 .. $#ar ) {
                        $ar[$i] = normalize_item( $ar[$i] );
                    }
                    $ref->{condition} = \@ar;
                }
                else {
                    normalize_parens($value);
                }
            }
        }
        default {
            die "unexpected type: $type";
        }
    }
    return $ref;
}

# normalizes parentheses in a condition item
sub normalize_item {
    my $item = shift;
    return $item unless ref $item;
    if ( exists $item->{term} ) {
        return normalize_parens( $item->{term} );
    }
    elsif ( exists $item->{group} ) {

        # remove redundant parentheses
        while ( exists $item->{group}
            && @{ $item->{group}{condition}{item} } == 1 )
        {
            $item = $item->{group}{condition}{item}[0];
        }
        return normalize_parens( $item->{group} // $item->{term} );
    }
    else {
        die 'items in a condition are expected to be either <term> or <group>';
    }
}

# some functions to undo escaping and normalize strings

sub clean_literal {
    my $m = shift;
    $m = substr $m, 1, -1;
    return clean_escapes($m);
}

sub clean_pattern {
    my $m = shift;
    return clean_special($m, '~~');
}

sub clean_special {
    my ($m, $p) = @_;
    $m = substr $m, 1, -1;
    my $r = '';
    my $i = 0;
    {
        my $j = index $m, $p, $i;
        if ( $j > -1 ) {
            $r .= substr $m, $i, $j - $i + 1;
            $i = $j + 2;
            redo;
        }
        else {
            $r .= substr $m, $i;
        }
    }
    return $r;
}

sub clean_regex {
    my $m = shift;
    return clean_special($m, '\\/');
}

sub clean_mregex {
    my ($m, $mods) = @_;
    my $p = '\\' . substr $m, -1, 1;
    $m = clean_special($m, $p);
    return $m unless $mods;
    return qr/(?$mods:$m)/ . '';
}

sub clean_not {
    my $m = shift;
    return '!' if $m eq 'not';
    return $m;
}

sub clean_operator {
    my $m = shift;
    for ($m) {
        when ('and') { return '&' }
        when ('or')  { return '||' }
        when ('one') { return ';' }
    }
    return $m;
}

sub clean_escapes {
    my $m = shift;
    return '' unless $m;
    my $r = '';
    {
        my $i = index $m, '\\';
        if ( $i > -1 ) {
            my $prefix = substr $m, 0, $i;
            my $c = substr $m, $i + 1, 1;
            for ($c) {
                when ('b') { $c = "\b" }
                when ('f') { $c = "\f" }
                when ('n') { $c = "\012" }
                when ('r') { $c = "\015" }
                when ('t') { $c = "\t" }
                when ('v') { $c = "\013" }
            }
            $prefix .= $c;
            $m = substr $m, $i + 2;
            $r .= $prefix;
            redo;
        }
        else {
            $r .= $m;
        }
    }
    return $r;
}

sub end_punct {
    my $c = shift;
    for ($c) {
        when ('(') { return ')' }
        when ('{') { return '}' }
        when ('[') { return ']' }
        when ('<') { return '>' }
    }
    return $c;
}

sub mods_test {
    my $mods = shift;
    my %types;
    for ( my ($i,$lim) = (0, length $mods); $i < $lim; ++$i) {
        $types{substr $mods, $i, 1} = 1;
    }
    return length $mods == scalar keys %types;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Grammar - parses TPath expressions into ASTs

=head1 VERSION

version 1.007

=head1 SYNOPSIS

    use TPath::Grammar qw(parse);

    my $ast = parse('/>a[child::b || @foo("bar")][-1]');

=head1 DESCRIPTION

C<TPath::Grammar> exposes a single function: C<parse>. Parsing is a preliminary step to
compiling the expression into an object that will select the tree nodes matching
the expression.

C<TPath::Grammar> is really intended for use by C<TPath> modules, but if you want 
a parse tree, here's how to get it.

Also exportable from C<TPath::Grammar> is C<%AXES>, the set of axes understood by TPath
expressions. See L<TPath> for the list and explanation.

=head1 FUNCTIONS

=head2 parse

Converts a TPath expression to a parse tree, normalizing boolean expressions
and parentheses, unescaping escaped strings, folding constants, and otherwise 
optimizing the parse tree and preparing it for compilation. 

C<parse> throws an exception (dies) if the expression is is unparsable or, in 
some cases, contains an impossible condition, C<[1=2]>, for example. Otherwise,
it returns a hashref.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
