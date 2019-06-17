package PMLTQ::Grammar;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Grammar::VERSION = '3.0.2';
# ABSTRACT: Provides L<Parse::RecDescent> grammar for parsing PML-TQ queries

use 5.006;
use strict;
use warnings;

sub grammar {
  do {local $/; <DATA>};
}

1;

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Grammar - Provides L<Parse::RecDescent> grammar for parsing PML-TQ queries

=head1 VERSION

version 3.0.2

=head1 AUTHORS

=over 4

=item *

Petr Pajas <pajas@ufal.mff.cuni.cz>

=item *

Jan Štěpánek <stepanek@ufal.mff.cuni.cz>

=item *

Michal Sedlák <sedlak@ufal.mff.cuni.cz>

=item *

Matyáš Kopp <matyas.kopp@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Institute of Formal and Applied Linguistics (http://ufal.mff.cuni.cz).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
{
  no warnings 'uninitialized'; # suppress uninitialized warnings
  # TODO: find solution for this so we can have warnings on
  $skip = '\s*(?:[#][^\n]*\s*)*';

  {
    package PMLTQ::ParserError;
    use UNIVERSAL::DOES;
    use overload '""' => \&as_text;
    sub new {
      my $class=shift;
      my $array_ref = shift;
      bless $array_ref, $class;
    }
    sub as_text {
      my $self = shift;
      return 'Parse error at line '.$self->line.': '.$self->message;
    }
    sub message { return $_[0]->[0] }
    sub line    { return $_[0]->[1] }
  }

  sub report_error {
    my ($thisparser,$rule,$text)=@_;
    die
    Treex::PML::TreeQuery::ParserError->new($thisparser->{errors}[0]||['Syntax error in '.$rule.' near '.substr($$text,0,20).'...',1]);
  }
  sub new_node {
    my ($hash,$children)=@_;
    my $new = Treex::PML::Factory->createNode($hash,1);
    if ($children) {
      if (ref($children) eq 'ARRAY') {
         for (reverse @$children) {
            if (UNIVERSAL::DOES::does($_,'Treex::PML::Node')) {
              $_->paste_on($new)
            } else {
               warn "new_node: child of $hash->{'#name'} is not a node:\n".
                    Data::Dumper::Dumper([$_]);
            }
         }
      } else {
        warn "new_node: 2nd argument of constructor to $hash->{'#name'} is not an ARRAYref:\n".
        Data::Dumper::Dumper([$children]);
      }
    }
    return $new;
  }
  sub new_struct {
    return Treex::PML::Factory->createStructure($_[0],1);
  }
  sub new_relation {
    my ($type,$opts)=@_;
    $opts||={};
    $opts->{label}||=$type;
    return Treex::PML::Factory->createSeq([
      Treex::PML::Seq::Element->new( 
        $type => Treex::PML::Factory->createContainer(undef,$opts)
      )
    ]);
  }
  sub _error ($;$){
    # Parse::RecDescent::_old_error(@_);
    warn("Syntax error at line $_[1]: $_[0]\n");
    return 1;
  }
  sub parse_or_die {
    my $self=shift;
    my $rule=shift;
    #local *Parse::RecDescent::_old_error = \&Parse::RecDescent::_error;
    #local *Parse::RecDescent::_error = \&_error;
    #local *Parse::RecDescent::ERROR;
    $self->$rule(@_);
  } 
  BEGIN {
  no strict qw(refs);
  no warnings 'redefine';
  foreach my $r (qw(query selectors filters node test expression flat_expression
          conditions column_expression)) {
    my $rule=$r;
    *{__PACKAGE__."::parse_".$rule} = sub {
        my $self=shift;
        my $call = "pmltq_$rule";
        my $old_error = \*Parse::RecDescent::_error;
        my @captured_errors;
        *Parse::RecDescent::_error = sub ($;$) { push @captured_errors, [@_] };
        my $ret = $self->$call(@_);
        *Parse::RecDescent::_error = $old_error;
        if (@captured_errors) {
          my %seen;
          croak(join("\n",
            grep !$seen{$_}++,
            map {
             my $e="Syntax error at line $_->[1]: $_->[0]";
             $e=~s/\r//g;
             $e;
            } @captured_errors) );
        } elsif (!defined($ret)) {
          die "Unknown syntax error while parsing $rule\n";
        }
        return $ret;
      };
  }
  }
}

pmltq_query: selectors output_filters_or_query_end
       { $return=new_node({ 
           $item[2] ? ('output-filters' => $item[2]) : ()
          },$item[1]);
          1;
       }
       | selectors ';' selector { $return=new_node({},[@{$item[1]},$item[3]]) }
        # this should be covered by the 1st production,
        # added just for error reporting from last selector
       | <error> # { report_error($thisparser,'query',\$text); } <reject>

pmltq_selectors: selectors { $return=$item[1] } | <error>

pmltq_filters: output_filters end_of_query
       { $return=@{$item[1]}; 1 }
     | <error> # { report_error($thisparser,'filter',\$text); } <reject>

pmltq_node: (member_selector|nested_selector|optional_nested_selector) end_of_query { $item[1] }
     | <error> # { report_error($thisparser,'node',\$text); } <reject>

pmltq_test: test end_of_query { $item[1] }
     | <error> # { report_error($thisparser,'test',\$text); } <reject>

pmltq_expression: expression end_of_string { $item[1] }
     | <error> # { report_error($thisparser,'expression',\$text); }

pmltq_flat_expression: flat_expression end_of_string { $item[1] }
     | <error> # { report_error($thisparser,'expression',\$text); }

pmltq_conditions: lone_conditions(?) end_of_conditions { $item[1][0] }
     | <error> #  { report_error($thisparser,'condition',\$text); }

pmltq_column_expression: column_expression end_of_string { $item[1] }
     | <error> # { report_error($thisparser,'column_expression',\$text); }

output_filters_or_query_end: 
            (';')(?) end_of_query { $return=[] }
            | (';')(?) ...'>>' <commit> output_filters comma_or_end_of_query
             { $return = $item[4] }
            | <error?> <reject>

content_look_ahead: /(\s*\d+\s*\])/ | /\s*\]\s*\//

selector: /(?!>>)/ type(?) name_assignment(?) '[' ...!content_look_ahead <commit> conditions(?) /,?(?:\#[^\n]*\n|\s+)*/ ']' 
      { new_node({ '#name' => 'node', 'node-type' => $item[2][0], name => $item[3][0]}, $item[7][0]) }
    | <error?> <reject>

selectors: <leftop: toplevel_selector ';' toplevel_selector>
         | <error>

toplevel_selector: /(?!>>)/ ('+')(?) selector { 
  $return = $item[3]; 
  $return->{overlapping}=$item[2][0] ? 1 : 0;
} 
| <error>

output_filters: filter(s?) return <commit> (filter | return | <error>)(s?)
              { Treex::PML::Factory->createList([@{$item[1]}, $item[2], @{$item[4]}],1) }
              | <error?> <reject>

return: '>>' <commit> group_by(?) ('distinct')(?) columns sort_by(?) (';')(?) 
             { $return=Treex::PML::Factory->createStructure({ 
                'return' => $item[5],
                'distinct' => scalar(@{$item[4]}),
                'group-by' => $item[3][0] ? $item[3][0][0] : undef,
                'sort-by'  => $item[6][0] ? Treex::PML::Factory->createList([@{$item[6][0]}],1) : undef,
               },1)
             }
           | <error?> <reject>

columns: <leftop: flat_column_expression ',' flat_column_expression>  (',')(?)
            { $return=Treex::PML::Factory->createList($item[1],1) }
       | <error:Expecting a column list at EOF> 

filter: />>\s*(?:filter|where)/ <commit> col_comma_clause  {
        $return=Treex::PML::Factory->createStructure({'where'=>new_node({'#name'=>'and'},[$item[3]])})
      }     
      | <error?> <reject>
group_by: 'for' <commit> columns 'give' { [$item[3]] } 
        | 'give' <commit> { [] }
        | <error?> <reject>

sort_by: /(?:>>(?:\#[^\n]*\n|\s+)*)?/ 'sort' <commit> ('by')(?) <leftop: sort_term ',' sort_term> { $item[5] }
       | <error?> <reject>

sort_term: column_reference ('asc'|'desc')(?)
           { $return = $item[1].($item[2][0] ? ' '.$item[2][0] : ''); 1 }

column_expression: <leftop: column_exp OP column_exp>
                   { @{$item[1]}>1 ? ['EXP',@{$item[1]}] : $item[1][0] }

flat_column_expression: <rulevar: ($start,$t)> 
          | { ($start,$t)=($thisoffset,$text) } <leftop: column_exp OP column_exp>
            { $return=substr($t,0,$thisoffset-$start); $return=~s/^\s*//; 1 }

column_exp: column_term | analytic_function | if_function

column_term: '(' <commit> column_expression ')' { $return=$item[3] }
             | column_reference <commit>  { $return=$item[1] }
             | result_function  { $return=$item[1] }
             | attribute_path    { $return=$item[1] }
             | selector_name         { $return='$'.$item[1] }
             | literal          { $return=$item[1] }
             | <error>

result_function: (FUNC|'first_defined') <skip: ''> '(' <commit> <skip: '\s*(?:[#][^\n]*\s*)*'> result_arguments(?) ')'
                 { ['FUNC', $item[1],$item[6][0] ] }

analytic_function: ANALYTIC_FUNC <skip: ''> '(' <commit> <skip: '\s*(?:[#][^\n]*\s*)*'> 
                 result_arguments(?)
                 over_clause(?) ')'
                 { ['ANALYTIC_FUNC', $item[1], $item[6][0], @{$item[7][0]||[]} ] }

if_function: /if\s*\(/ <commit> col_test ',' column_expression ',' column_expression ')'
                 { [ 'IF', $item[3],$item[5],$item[7] ] }

over_clause: 'over' over_columns sort_by_clause(?) { [$item[2],$item[3][0]] }
           | sort_by_clause { [['ALL'],$item[3][0]] }

sort_by_clause: /sort\s+by/ <leftop: column_sort_term ',' column_sort_term> { $item[2] }

column_sort_term: column_term ('asc'|'desc')(?) { [$item[1],@{$item[2]}] }

over_columns: 'all' { ['ALL'] } 
    | <leftop: column_term ',' column_term> { $item[1] }

result_arguments: <leftop: column_expression ',' column_expression>
          { $item[1] }

type: NODE_TYPE .../\$|\[/
      { $return = $item[1] }

name_assignment: selector_name ':=' <commit> ...'[' { $return = $item[1] }
       | <error?> <reject>

lone_conditions: <leftop: condition /and|,/ condition> end_of_conditions
           { $return = $item[1] }
          | <error>

conditions: <leftop: condition /and|,/ condition> { $return = $item[1] }
          | <error?> <reject>

condition: optional_nested_selector   { $return = $item[1] }
         | member_selector { $return = $item[1] }
         | nested_selector    { $return = $item[1] }
         | test { $return = $item[1] }
         | <error>

member_selector: 'member' ('::')(?) member { $return = $item[3] }

nested_selector: ('+')(?) RELATION(?) selector {
  $return = $item[3]; 
  $return->{overlapping}=$item[1][0] ? 1 : 0;
  $return->{relation}=$item[2][0];
  1 
}

ref: RELATION(?) selector_name
     { $return = new_node({ '#name' => 'ref', target=>$item[2], relation=>$item[1][0] });
     }

optional_nested_selector: '?' nested_selector
         { $return=$item[2]; $return->{optional}=1; 1 }

test: or_clause

simple_test: predicate | subquery_test | ref 
           | '(' comma_clause ')' { $return = $item[2] }

comma_clause: <leftop: test ',' test>
          { $return =  (@{$item[1]} > 1 ? new_node({ '#name' => 'and'}, $item[1]) : $item[1][0]) }

or_clause: <leftop: and_clause 'or' and_clause>
           { $return =  (@{$item[1]} > 1 ? new_node({ '#name' => 'or'}, $item[1]) : $item[1][0]) }

and_clause: <leftop: not_clause 'and' not_clause>
          { $return = (@{$item[1]} > 1 ? new_node({ '#name' => 'and'}, $item[1]) : $item[1][0]) }

not_clause: '!' <commit> simple_test
          {  $return = $item[3];
             if ($return->{'#name'} eq 'and') {
               $return->{'#name'} = 'not';
             } else {
               $return = new_node({ '#name' => 'not'}, [$return])
             }
          }
          | simple_test

predicate: VAR_OR_SELF /!?=/ VAR_OR_SELF
           { 
             $return = new_node({ '#name' => 'test', a=>'$'.$item[1], operator=>$item[2], b=>'$'.$item[3] });
             # if ($item[2] eq '!=') {
             #    $return = new_node({ '#name' => 'not'}, [$return])
             # }
           }
         | flat_expression /!?\s*in/ <commit> flat_set_expression
           { my $op = $item[2]; $op=~s/\s+//g;
             new_node({ '#name' => 'test', a=>$item[1], operator=>$op, b=>$item[4] })
           }
         | flat_expression CMP <commit> flat_expression
           { 
              my $op = $item[2];
              # my $negate = $op=~s/^!// ? 1 : 0;
              $return = new_node({ '#name' => 'test', a=>$item[1], operator=>$op, b=>$item[4] });
              # $return = new_node({ '#name' => 'not'}, [$return]) if $negate;
           }

flat_set_expression: <rulevar: ($start,$t)> 
                   | { ($start,$t)=($thisoffset,$text) } 
                     '{' <leftop: flat_expression ',' flat_expression> '}'
                     { $return=substr($t,0,$thisoffset-$start); $return=~s/^\s*//; 1 }

flat_expression: <rulevar: ($start,$t)> 
          | { ($start,$t)=($thisoffset,$text) } <leftop: term OP term>
            { $return=substr($t,0,$thisoffset-$start); $return=~s/^\s*//; 1 }

expression: '{' <commit> <leftop: expression ',' expression> '}'
            { ['SET',@{$item[3]}] }
          | <leftop: term OP term>
            { @{$item[1]}>1 ? ['EXP',@{$item[1]}] : $item[1][0] }
          | VAR_OR_SELF { '$'.$item[1] }
          | <error?> <reject>

term: '(' <commit> expression ')' { $return=$item[3] }
    | every            { $return=$item[1] }
    | function         { $return=$item[1] }
    | simple_attribute { $return=$item[1] }
    | attribute_path    { $return=$item[1] }
    | literal          { $return=$item[1] }
    | VAR_OR_SELF      { $return='$'.$item[1] }
    #| <error>

simple_attribute: TYPE_PREFIX(?) ('[]' | 'content()' | indexed_name | XMLNAME ) <skip: ''> ('/' step)(s?)
                  { ['ATTR',@{$item[1]}, $item[2], @{$item[4]}] }
                #| <error>

indexed_name: /\[\s*[0-9]+\s*\]/ <skip: ''> XMLNAME { $item[1].$item[3] }   
            | XMLNAME <skip: ''> /\[\s*[0-9]+\s*\]/ { $item[1].$item[3] }   

step: 'content()' { $item[1] }
    | '.' { $item[1] }
    | indexed_name
    | XMLNAME { $item[1] }
    | /\[\s*[0-9]+\s*\]/ { $item[1] }
    | '[]' { $item[1] }
    | <error>

attribute_path: VAR_OR_SELF <skip: ''> '.' <commit> simple_attribute
               { ['REF_ATTR',$item[1],$item[5]] }
             | <error?> <reject>

every: '*' <commit> ( attribute_path | simple_attribute )
               { [ 'EVERY',$item[3] ] }
     | <error?> <reject>

function: FUNC <skip: ''> '(' <skip: '\s*(?:[#][^\n]*\s*)*'> <commit> arguments(?) ')'
          { ['FUNC', $item[1],$item[6][0] ] }
          | <error?> <reject>

arguments: <leftop: argument ',' argument>
          { $item[1] }

argument: expression { $item[1] }
        | VAR_OR_SELF { '$'.$item[1] }
        | <error>

subquery_test: subquery { $item[1] }
             | member_or_subq {
                 $return=$item[1];
                 $return->{occurrences}=new_struct({ min=>1 });
                 1; 
               }

subquery: occurrences_alt <commit> member_or_subq {
            $return = $item[3];
            $return->{occurrences}=$item[1];
            1
          } 
          | <error?> <reject>

member_or_subq: 'member' ('::')(?) member {
                  $return=$item[3]; 
                  $return->{'#name'}='subquery';
                  1;
                }
              | RELATION(?) selector { 
                  $return=$item[2]; 
                  $return->{'#name'}='subquery';
                  $return->{relation}=$item[1][0];
                  1;
                }

member: simple_attribute name_assignment(?) '[' /(?!\s*\d+\s*\])/ <commit> conditions(?) /,?(?:\#[^\n]*\n|\s+)*/ ']' 
      { 
        my $attr = $item[1];
        my $path = join('/',@$attr[1..$#$attr]);
        new_node({ '#name' => 'node', 
                   'node-type' => $path, 
                   'name' => $item[2][0],
                   'relation' => new_relation('member'),
                 }, $item[6][0]) 
      } 
    | <error?> <reject>

col_test: col_or_clause

col_simple_test: col_predicate
               | '(' col_comma_clause ')' { $return = $item[2] }

col_comma_clause: <leftop: col_test ',' col_test>
          { $return =  (@{$item[1]} > 1 ? new_node({ '#name' => 'and'}, $item[1]) : $item[1][0]) }

col_or_clause: <leftop: col_and_clause 'or' col_and_clause>
           { $return =  (@{$item[1]} > 1 ? new_node({ '#name' => 'or'}, $item[1]) : $item[1][0]) }

col_and_clause: <leftop: col_not_clause 'and' col_not_clause>
          { $return = (@{$item[1]} > 1 ? new_node({ '#name' => 'and'}, $item[1]) : $item[1][0]) }

col_not_clause: '!' <commit> col_simple_test
          {  $return = $item[3];
             if ($return->{'#name'} eq 'and') {
               $return->{'#name'} = 'not';
             } else {
               $return = new_node({ '#name' => 'not'}, [$return])
             }
          }
          | col_simple_test

col_predicate: flat_column_expression /!?\s*in/ <commit> flat_set_col_expression
           { my $op = $item[2]; $op=~s/\s+//g;
             new_node({ '#name' => 'test', a=>$item[1], operator=>$op, b=>$item[4] })
           }
         | flat_column_expression CMP <commit> flat_column_expression
           { 
              my $op = $item[2];
              $return = new_node({ '#name' => 'test', a=>$item[1], operator=>$op, b=>$item[4] });
           }

flat_set_col_expression: <rulevar: ($start,$t)> 
                       | { ($start,$t)=($thisoffset,$text) } 
                         '{' <leftop: literal ',' literal> '}'
                         { $return=substr($t,0,$thisoffset-$start); $return=~s/^\s*//; 1 }

occurrences_alt: <leftop: occurrences '|' occurrences> 'x' <commit>
            { @{$item[1]}>1 ? Treex::PML::Factory->createAlt([@{$item[1]}],1) : $item[1][0] }
           | <error?> <reject>

occurrences: NUMBER '..' <commit> NUMBER
             { $return = new_struct({ min=>$item[1], max=>$item[4] }) }
           | NUMBER (/[-+]/)(?) { 
             $return = !$item[2][0] 
                   ? new_struct({ min=>$item[1], max=>$item[1] })
                   : new_struct({ ($item[2][0] eq '-' ? 'max' : 'min') =>
                                  $item[1] })
             }
           | <error?> <reject>

literal : NUMBER
        | STRING

VAR_OR_SELF: '$$' { $return='$' }
           | selector_name

selector_name: /\$[[:alpha:]_][[:alnum:]_]*\b/
          { $return=$item[1]; $return=~s/^\$//; 1 }

RELATION: /(?:sibling|descendant|ancestor|depth-first-precedes|depth-first-follows|order-precedes|order-follows)\b/ <skip:''> '{' 
          <commit> <skip:'\s*(?:[#][^\n]*\s*)*'> (/-?[0-9]+/)(?) ',' (/-?[0-9]+/)(?) '}' /\s*(?!->)(::)?/
          { new_relation($item[1],{min_length=>$item[6][0],max_length=>$item[8][0]}) }
        | /(?:child|parent|sibling|descendant|ancestor|same-tree-as|same-document-as|depth-first-precedes|depth-first-follows|order-precedes|order-follows)\b/  /\s*(?!->)(::)?/
          { new_relation($item[1]) }
        |  { $Treex::PML::TreeQuery::user_defined ? 1 : undef } 
           /(?:${Treex::PML::TreeQuery::user_defined})\b/
          <skip:''> '{' <commit> <skip:'\s*(?:[#][^\n]*\s*)*'> (/[0-9]+/)(?) ',' (/[0-9]+/)(?) '}'
           /\s*(?!->)(::)?/
          { new_relation('user-defined',{label => $item[2],category=>'implementation',
          min_length=>$item[7][0], max_length=>$item[9][0]}) }
        |  { $Treex::PML::TreeQuery::user_defined ? 1 : undef } 
           /(?:${Treex::PML::TreeQuery::user_defined})\b/
           /\s*(?!->)(::)?/
          { new_relation('user-defined',{label => $item[2],category=>'implementation'}) }
        | { $Treex::PML::TreeQuery::pmlrf_relations ? 1 : undef }
          /(?:${Treex::PML::TreeQuery::pmlrf_relations})\b/
          <skip:''> '{' <commit> <skip:'\s*(?:[#][^\n]*\s*)*'> (/[0-9]+/)(?) ',' (/[0-9]+/)(?) '}'
          /\s*(?!::)(->)?/
          { new_relation('user-defined',{label => $item[2],
          category=>'pmlrf',
          min_length=>$item[7][0], max_length=>$item[9][0]}) }
        | { $Treex::PML::TreeQuery::pmlrf_relations ? 1 : undef }
          /(?:${Treex::PML::TreeQuery::pmlrf_relations})\b/
          /\s*(?!::)(->)?/
          { new_relation('user-defined',{label => $item[2],category=>'pmlrf'}) }
        |
          /[_a-zA-Z][-.\/_a-zA-Z]*(?=\s*->|\s*\$[[:alpha:]_][[:alnum:]_]*\b(?!\s*:=)|\s+${Treex::PML::Schema::CDATA::Name}\s*(?:\[|\$))/ 
          /\s*(?!::)(->)?/
          { new_relation('user-defined',{label => $item[1],category=>'pmlrf'}) }
        |
          /[_a-zA-Z][-.\/_a-zA-Z]*(?=(?:\{[0-9]*,[0-9]*\})(?:\s*->|\s*\$[[:alpha:]_][[:alnum:]_]*\b(?!\s*:=)|\s+${Treex::PML::Schema::CDATA::Name}\s*(?:\[|\$)))/ 
          <skip:''> '{' <commit> <skip:'\s*(?:[#][^\n]*\s*)*'> (/[0-9]+/)(?) ',' (/[0-9]+/)(?) '}'
          /\s*(?!::)(->)?/
          { new_relation('user-defined',{label => $item[1], category=>'pmlrf', min_length=>$item[6][0], max_length=>$item[8][0]}) }

FUNC: /(descendants|lbrothers|rbrothers|sons|depth_first_order|order_span_min|order_span_max|depth|lower|upper|length|substr|tr|replace|substitute|match|ceil|floor|round|trunc|percnt|name|type_of|id|file|tree_no|address|abs|exp|power|log|sqrt|ln)\b/

ANALYTIC_FUNC: /min|max|sum|avg|count|ratio|concat|row_number|rank|dense_rank/

column_reference: /^\$[1-9][0-9]*/

CMP: /!?=|!?~\*?|[<>]=?/

OP: /[-+*&]|div|mod/

STRING: /'([^'\\]+|\\.)*'|"([^"\\]+|\\.)*"/

NUMBER: /-?[0-9]+(\.[0-9]+)?/

XMLNAME: /${Treex::PML::Schema::CDATA::Name}/o

NODE_TYPE: /\*|${Treex::PML::Schema::CDATA::NCName}(?:[:][*])?/o

TYPE_PREFIX: /${Treex::PML::Schema::CDATA::Name}\s*\?/o

end_of_query: /^\Z/

comma_or_end_of_query: (',')(?) /^\Z/

end_of_string: /^\Z/

end_of_conditions: /,?(?:\#[^\n]*\n|\s+)*\Z/