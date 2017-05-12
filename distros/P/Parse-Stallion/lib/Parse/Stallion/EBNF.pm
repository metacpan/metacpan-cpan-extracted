#Copyright 2008-10 Arthur S Goldstein

package Parse::Stallion::EBNF;
use Carp;
use strict;
use warnings;
use Parse::Stallion;
our $VERSION='0.7';

sub ebnf {
  shift;
  my $parser = shift;

  my @queue;
  unshift @queue, keys %{$parser->{rule}};
  my $start_rule = $parser->{start_rule};
  unshift @queue, $start_rule;

  my $results;
  my %covered;
  while (my $rule = shift @queue) {
    if (!$covered{$rule}++) {
      $results .= "$rule = ";
      if ($parser->{rule}->{$rule}->{rule_type} eq 'MULTIPLE') {
        my $min = $parser->{rule}->{$rule}->{minimum_child};
        my $max = $parser->{rule}->{$rule}->{maximum_child};
        if ($min == 0 && $max == 1) {
          $results .= "[ ";
          $results .= $parser->{rule}->{$rule}->{subrule_list}->[0]->{name};
          $results .= " ]";
        }
        else {
          $results .= "{ ";
          $results .= $parser->{rule}->{$rule}->{subrule_list}->[0]->{name};
          if ($min != 0 || $max != 0) {
            $results .= "($min, $max)";
          }
          $results .= " }";
        }
      }
      elsif ($parser->{rule}->{$rule}->{rule_type} eq 'AND') {
        $results .= join (" , ",
         map {$_->{name}} @{$parser->{rule}->{$rule}->{subrule_list}});
      }
      elsif ($parser->{rule}->{$rule}->{rule_type} eq 'OR') {
        $results .= join (" | ",
         map {$_->{name}} @{$parser->{rule}->{$rule}->{subrule_list}});
      }
      elsif ($parser->{rule}->{$rule}->{rule_type} eq 'LEAF') {
        if (defined $parser->{rule}->{$rule}->{leaf_display}) {
          $results .= $parser->{rule}->{$rule}->{leaf_display};
        }
      }
      else {
        croak "Rule $rule unknown type ".$parser->{rule}->{$rule}->{rule_type};
      }
      if ($parser->{rule}->{$rule}->{subrule_list}) {
        my @new_rules;
        foreach my $subrule (@{$parser->{rule}->{$rule}->{subrule_list}}) {
          push @new_rules, $subrule->{name};
        }
        unshift @queue, @new_rules;
      }
      if ($parser->{rule}->{$rule}->{minimize_children}) {
        $results .= ' -MATCH_MIN_FIRST- ';
      }
      if ($parser->{rule}->{$rule}->{parsing_evaluation}) {
        $results .= ' -EVALUATION- ';
      }
      if ($parser->{rule}->{$rule}->{parsing_unevaluation}) {
        $results .= ' -UNEVALUATION- ';
      }
      if ($parser->{rule}->{$rule}->{use_string_match}) {
        $results .= ' -USE_STRING_MATCH- ';
      }
      if ($parser->{rule}->{$rule}->{match_once}) {
        $results .= ' -MATCH_ONCE- ';
      }
      if ($parser->{rule_info}->{$rule}) {
        $results .= ' -RULE_INFO- ';
      }
      $results .= " ;\n";
    }
  }
  return $results;
}

my %ebnf_rules = (
   ebnf_rule_list => A(L(PF(sub{$_[0]->{parse_hash}->{max_position} = 0;
    return 1, undef, 0})), 'some_white_space',
    M(A(O('rule','failed_rule'),'some_white_space')),
    E(sub {
        my $parse_hash = $_[3];
        my $any_errors = 0;
        $parse_hash->{errors} = [];
        if ($_[0]->{failed_rule}) {
          push @{$parse_hash->{errors}}, @{$_[0]->{failed_rule}};
          $any_errors = 1;
        }
       foreach my $rule (@{$_[0]->{rule}}) {
         if ($rule->{error}) {
           push @{$parse_hash->{errors}}, $rule->{error};
           $any_errors = 1;
         }
       }
       if ($any_errors) {croak join("\n",@{$parse_hash->{errors}})}
       return $_[0]->{rule};})),
   rule =>
    A('rule_name', 'some_white_space', qr/\=/, 'some_white_space',
     'rule_def', 'some_white_space', qr /\;/,
     E(sub {
         return {rule_name => $_[0]->{rule_name},
          rule_definition => $_[0]->{rule_def}}})),
   real_white_space => A(qr/\s/, 'some_white_space'),
   some_white_space => A(L(PF(
    sub {my $parameters = shift;
      my $cv = $parameters->{current_position};
      my $ph = $parameters->{parse_hash};
      if ($ph->{max_position} < $cv) {
        $ph->{max_position} = $cv;
      }
      return 1, undef, 0;
    })), O(
    A(qr/\s*\#/, 'comment', 'some_white_space'),
    qr/\s*/,
   )),
   rule_def =>
    O(
     A(qr/\(/, 'some_white_space', 'the_rule', 'some_white_space', qr/\)/,
      Z(A('some_white_space', 'eval_subroutine'))),
     A('the_rule'),
      E(sub {
         my $the_rule = $_[0]->{the_rule};
         my $rule_def;
         if ($_[0]->{eval_subroutine}->{sub}) {
           push @{$the_rule->{elements}}, $_[0]->{eval_subroutine}->{sub};
         }
         if ($the_rule->{rule_type} eq 'AND') {
           $rule_def = A(@{$the_rule->{elements}});
         }
         elsif ($the_rule->{rule_type} eq 'OR') {
           $rule_def = O(@{$the_rule->{elements}});
         }
         elsif ($the_rule->{rule_type} eq 'LEAF') {
           $rule_def = L(@{$the_rule->{elements}});
         }
         elsif ($the_rule->{rule_type} eq 'MULTIPLE') {
           $rule_def = M(@{$the_rule->{elements}});
         }
         elsif ($the_rule->{rule_type} eq 'OPTIONAL') {
           $rule_def = Z(@{$the_rule->{elements}});
         }
         return $rule_def})),
   the_rule => O('leaf', 'quote', 'pf_pb', 'multiple', 'optional', 'and', 'or'),
   comment => qr/[^\n]*/,
   failed_rule => A(
    L(PF(sub {${$_[0]->{__current_node_ref}}->{error_position} =
     $_[0]->{parse_hash}->{max_position};
     my $new_position = $_[0]->{current_position};
     if ($new_position < $_[0]->{parse_hash}->{max_position}) {
       $new_position = $_[0]->{parse_hash}->{max_position};
     }
     return 1, undef, 0;})),
    qr/[^;]*\;/,
    E(sub {my (undef, $parameters) = @_;
      my $text = $parameters->{parse_this_ref};
      my $pos = $parameters->{current_node}->{error_position} || 0;
      my ($line, $position) = LOCATION($text, $pos);
      my $before_length = 10;
      my $before_start = $pos - 10;
      if ($pos < 10) {
        $before_length = $pos;
        $before_start = 0;
      }
      my $before = substr($$text, $before_start, $before_length);
      $before =~ s/.*\s(.+)/$1/;
      my $after = substr($$text, $pos, 10);
      $after =~ s/(.+?)\s(.*)/$1/;
      return "Error at line $line tab stop $position near '$before".$after."'";
     })),
   and => A( 'element' ,
     M(A('real_white_space', 'element')),
    E(sub {
     return {rule_type => 'AND', elements => $_[0]->{element}};})),
   element => A(Z(A({alias=>'rule_name'}, qr/\./)), 'sub_element',
    E( sub {
      if (defined $_[0]->{alias}) {
        return {$_[0]->{alias} => $_[0]->{sub_element}}
      }
      return $_[0]->{sub_element}})),
   sub_element => O('rule_name', 'sub_rule',
    'optional_sub_rule',
    'multiple_sub_rule', 'leaf_sub_rule', 'pf_pb_subrule', 'quote_sub_rule',
    'use_string_match', 'match_once', 'match_min_first'),
   use_string_match => L(qr/\=SM/,
    E(sub {return USE_STRING_MATCH})),
   match_once => L(qr/\=MO/,
    E(sub {return MATCH_ONCE})),
   match_min_first => L(qr/\=MMF/,
    E(sub {return MATCH_MIN_FIRST})),
   optional_sub_rule => A( qr/\[/, 'some_white_space',
     'rule_def', 'some_white_space', qr/\]/i,
    E(sub {
      return Z($_[0]->{rule_def});})),
   multiple_sub_rule => A( qr/\{/,
    'some_white_space', 'rule_def', 'some_white_space', qr/\}/,
    Z('use_min_first'), Z('min_max'),
    E(sub {
      my $min = 0;
      my $max = 0;
      if ($_[0]->{min_max}) {
        $min = $_[0]->{min_max}->{min};
        $max = $_[0]->{min_max}->{max};
      }
      if ($_[0]->{use_min_first}) {
        return M($_[0]->{rule_def},$min,$max, MATCH_MIN_FIRST());
      }
      return M($_[0]->{rule_def},$min,$max);}
     )),
   sub_rule => A( qr/\(/, 'some_white_space', 'rule_def', 'some_white_space',
    qr/\)/,
    E(sub { return $_[0]->{rule_def};})
   ),
   rule_name => qr/[a-zA-Z]\w*/,
   or => A( 'element' , M(A('some_white_space', qr/\|/, 'some_white_space',
    'element'), 1, 0),
    E(sub {return {rule_type => 'OR', elements => $_[0]->{element}}})),
   multiple => A( qr/\{/, 'some_white_space',
   'element', 'some_white_space', qr/\}/, Z('use_min_first'),
    Z('min_max'),
    E(sub {
      my $min = 0;
      my $max = 0;
      if ($_[0]->{min_max}) {
        $min = $_[0]->{min_max}->{min};
        $max = $_[0]->{min_max}->{max};
      }
      if ($_[0]->{use_min_first}) {
        return {rule_type => 'MULTIPLE',
         elements => [$_[0]->{element},$min,$max, MATCH_MIN_FIRST()]};
      }
      return {rule_type => 'MULTIPLE', elements => [$_[0]->{element},$min,$max]}
     })),
   min_max => A(qr/\*/,{min=>qr/\d+/},qr/\,/,{max=>qr/\d+/}),
   use_min_first => qr/\?/,
   optional => A( qr/\[/, 'some_white_space',
    'element', 'some_white_space', qr/\]/,
    E(sub {
      return {rule_type => 'OPTIONAL', elements => [$_[0]->{element}]}
     })),
   quote_sub_rule => A( O(A(qr/q/i, qr/[^\w\s]/), qr/(\"|\')/), 'leaf_info',
    E(sub {my $li = $_[0]->{leaf_info}; substr($li, -1) = '';
      $li =~ s/(\W)/\\$1/g;
      return L(qr/$li/)})),
   quote => A( O(A(qr/q/i, qr/[^\w\s]/,), qr/(\"|\')/), 'leaf_info',
    E(sub {my $li = $_[0]->{leaf_info}; substr($li, -1) = '';
      $li =~ s/(\W)/\\$1/g;
      return {rule_type => 'LEAF', elements => [qr/$li/]}})),
   leaf_sub_rule => A( qr/qr/i, qr/[^\w\s]/, 'leaf_info',
    E(sub {my $li = $_[0]->{leaf_info}; substr($li, -1) = '';
      return L(qr/$li/)})),
   leaf => A( qr/qr/, qr/[^\w\s]/, 'leaf_info',
    Z({modifiers=>qr/\w+/}),
    E(sub {my $li = $_[0]->{leaf_info}; substr($li, -1) = '';
      if (defined $_[0]->{modifiers}) {
         $li = '(?' . $_[0]->{modifiers}. ')'.$li
      }
      return {rule_type => 'LEAF', elements => [qr/$li/]}})),
   leaf_info => L(PF(
    sub {my $parameters = shift;
      my $in_ref = $parameters->{parse_this_ref};
      my $pos = $parameters->{current_position};
      my $previous = substr($$in_ref, $pos-1, 1);
      pos $$in_ref = $pos;
      if ($$in_ref =~ /\G([^$previous]+$previous)/) {
        return 1, $1, length($1);
      }
      else {
        return 0;
      }
    }
   )),
   pf_pb_subrule => A('parse_forward',
    Z(A('some_white_space', 'parse_backtrack')),
    E (sub {
       if ($_[0]->{parse_backtrack}) {
         return L(PF($_[0]->{parse_forward}),
           PB($_[0]->{parse_backtrack}));
          };
       return L(PF($_[0]->{parse_forward}));
     }
   )),
   pf_pb => A('parse_forward', Z(A('some_white_space', 'parse_backtrack')),
     E(sub {
     if ($_[0]->{parse_backtrack}) {
       return {rule_type => 'LEAF', elements => [
         PF($_[0]->{parse_forward}),
         PB($_[0]->{parse_backtrack}),
        ]};
      }
      return {rule_type => 'LEAF', elements => [
        PF($_[0]->{parse_forward}),
       ]};
   })),
   quote_sub_rule => A( O(A(qr/q/i, qr/[^\w\s]/), qr/(\"|\')/), 'leaf_info',
    E(sub {my $li = $_[0]->{leaf_info}; substr($li, -1) = '';
      $li =~ s/(\W)/\\$1/g;
      return L(qr/$li/)})),
   quote => A( O(A(qr/q/i, qr/[^\w\s]/,), qr/(\"|\')/), 'leaf_info',
    E(sub {my $li = $_[0]->{leaf_info}; substr($li, -1) = '';
      $li =~ s/(\W)/\\$1/g;
      return {rule_type => 'LEAF', elements => [qr/$li/]}})),
   parse_backtrack => A( qr/B[^\w\s]/, 'sub_routine',
    E(sub {
       my $routine = eval $_[0]->{sub_routine}->{the_sub};
       if ($@) {croak $@};
       return $routine;})
   ),
   parse_forward => A( qr/F[^\w\s]/, 'sub_routine',
    E(sub {
       my $routine = eval $_[0]->{sub_routine}->{the_sub};
       if ($@) {croak $@};
       return $routine;})
   ),
   eval_subroutine => A( qr/S[^\w\s]/, 'sub_routine',
    E(sub {return {'sub' => SE($_[0]->{'sub_routine'}->{the_sub},
     '_matched_string')}})
   ),
   sub_routine => L(PARSE_FORWARD(
    sub {my $parameters = shift;
      my $in_ref = $parameters->{parse_this_ref};
      my $pos = $parameters->{current_position};
      my $previous = substr($$in_ref, $pos-1, 1);
      my $previous2 = substr($$in_ref, $pos-2, 1);
      pos $$in_ref = $pos;
      my $opposite;
      if ($previous eq '{') {$opposite = '}'};
      if ($previous eq '[') {$opposite = ']'};
      if (!defined $opposite) {return 0}
      if ($$in_ref =~ /\G(.*?$opposite($previous2))/s) {
        return 1, $1, length($1);
      }
      else {
        return 0;
      }
    }),
    E(sub {
       my $subroutine = shift;
       substr($subroutine, -2) = '';
       return {the_sub => $subroutine};
     }
   ))
);

our $ebnf_parser = new Parse::Stallion(\%ebnf_rules);
foreach my $mn (keys %{$ebnf_parser->{rule}}) {
  if (!$ebnf_parser->{rule}->{$mn}->{rule_type}) {
    warn "name generated $mn\n";
  }
}

use Parse::Stallion::EBNF;
my $ebnf_form = ebnf Parse::Stallion::EBNF($ebnf_parser);

sub ebnf_new {
  my $type = shift;
  my $rules_string = shift;
#print STDERR "rule string is $rules_string\n";
#  my @pt;
  my $rules_out = eval {$ebnf_parser->parse_and_evaluate(
    $rules_string
#    , {parse_trace => \@pt}
   )};
#use Data::Dumper;print STDERR "pt is ".Dumper(\@pt)."\n";
  if ($@) {croak "\nUnable to create parser due to the following:\n$@\n"};
#use Data::Dumper;print STDERR "ro is ".Dumper($rules_out)."\n";
  my %rules;
  foreach my $rule (@$rules_out) {
    my $rule_name = $rule->{rule_name};
    if ($rules{$rule_name}) {
      croak "Unable to create parse: Duplicate rule name $rule_name\n";
    }
    $rules{$rule_name} = $rule->{rule_definition};
  }
#use Data::Dumper;print STDERR "therules is ".Dumper(\%rules)."\n";
  my $new_parser = new Parse::Stallion(\%rules, {separator => '.'});
  return $new_parser;
}


1;

__END__

=head1 NAME

Parse::Stallion::EBNF - Output/Input parser in Extended Backus Naur Form.

=head1 SYNOPSIS

  #Output
  use Parse::Stallion;
  $parser = new Parse::Stallion(...);

  use Parse::Stallion::EBNF;
  $ebnf_form = ebnf Parse::Stallion::EBNF($parser);

  print $ebnf_form;

  #Input
  my $rules = '
    start = (number qr/\s*\+\s*/ number)
     S{return $number->[0] + $number->[1]}S;
    number = qr/\d+/;
  ';

  my $rule_parser = ebnf_new Parse::Stallion::EBNF($rules);

  my $value = $rule_parser->parse_and_evaluate('1 + 6');
  # $value should be 7

=head1 DESCRIPTION

=head2 Output

Given a parser from Parse::Stallion, creates a string that is
the parser's grammar in EBNF.

If LEAF_DISPLAY is passed in as a parameter to a LEAF rule, that
is also part of the output of a leaf node.  This can be useful, for instance,
to display a description of the code of a PARSE_FORWARD routine.

The following are appended to rules that have them defined:

        -MATCH_MIN_FIRST-
        -EVALUATION-
        -UNEVALUATION-
        -USE_STRING_MATCH-
        -MATCH_ONCE-
        -RULE_INFO-

=head2 Input

Use Parse::Stallion for more complicated grammars.

Enter a string with simple grammar rules, a parser is returned.

Each rule must be terminated by a semicolon.

Each rule name must consist of word characters (\w).

Format:

   <rule_name> = <rule_def>;

Four types of rules: 'and', 'or', 'leaf', 'multiple'/'optional' 

Rule names and aliases must start with a letter or underscore though
may contain digits as well.  They are case sensitive.

=head3 AND

'and' rule, the rule_def must be rule names separated by whitespace.

=head3 OR

'or' rule, the rule_def must be rule names separated by single pipes (|).

=head3 LEAF

'leaf' rule can be done on a string via 'qr' or 'q' or as a
parse_forward/optionally parse_backtract combination.

'leaf' rule, the rule_def can be a 'qr' or 'q'
followed by a non-space, non-word
character (\W) up to a repetition of that character.  What
is betweent the characters is treated as either a regular expression (if 'qr')
or a string (if 'q').  Additionally, if a string is within quotes or
double quotes it is treated as a string.  The following are the same:

  q/x\x/, q'x\x', 'x\x', "x\x",  qr/x\\x/, qr'x\\x'

The qr of a leaf is not the same as a perl regexp's declaration.  Notably,
one cannot escape the delimiting chars.  That is,
     qr/\//

is valid perl but not valid here, one could instead use

     qr+/+

which is also valid perl.

Modifiers are allowed and are inserted into the regexp via an extended
regex sequence:

         qr/abc/i

internally becomes

         qr/(?i)abc/

=head3 MULTIPLE/Optional

'multiple' rule, a rule name enclosed within curly braces {}.  Optionally
may have a minimum and maximum occurence by following the definition with
an asterisk min, max.
For example:

   multiple_rule = {ruleM}*5,0;

would have at least 5 occurences of ruleM.  The maximum is required and 0
sets it to unlimited.

Optional rules can be specified within square brackets.  The following
are the same:

  {rule_a}*0,1

  [rule_a]

To try to parse with the minimum occurences of a multiple rule first and
then go increasing order add a '?' after the right curly brace:

  multiple_rule2 ={ruleX}?;

  multiple_rule ={ruleX}?*3,9;

=head3 SUBRULES

Subrules may be specified within a rule by enclosing the subrule within
parentheses.  

=head3 ALIAS

An alias may be specified by an alias name followed by a dot:
the alias then a dot.  I.e.,

    rule_1 = rule_2 S{print $rule_2;}S;

    rule_3 = alias.rule_2 S{print $alias;}S;

    alias.qr/regex/

    alias.(rule1 rule2)

    alias.(rule1 | rule2)

=head3 EVALUATION

For the evaluation phase (see Parse::Stallion) any
rule can be enclosed within parentheses followed by
an evaluation subroutine that should be enclosed within S{ til }S.
Or else S[ til ]S.
The 'sub ' declaration is done internally.

Internally all subrules have variables created that contain
their evaluated values.  If a subrule's name may occur more than once it is
passed in an array reference.  See Parse::Stallion for details on
parameters passed to evaluation routine.  This saves on having to
create code for reading in the parameters.

Examples:

   rule = (number plus number) S{subroutine}S;

will create an evaluation subroutine string and eval:

  sub {
  my $number = $_[0]->{number};
  my $plus = $_[0]->{plus};
  my $_matched_string = MATCHED_STRING($_[1]);
  subroutine
  }

$number is an array ref, $plus is the returned value from subrule plus.

  number = (/\d+/) S{subroutine}S;

is a leaf rule, which only gets one argument to its subroutine:

  sub {
  my $_ = $_[0];
  my $_matched_string = MATCHED_STRING($_[1]);
  subroutine
  }

The variable, $_matched_string is set to the corresponding
matched string of the rule and the rule's descendants.  For leaf rules
this is the same as $_[0] .

Evaluation is only done after parsing unlike the option of during parsing
found in Parse::Stallion.

=head3 STRING_MATCH, MATCH_ONCE, MATCH_MIN_FIRST

By putting =SM within a rule (or subrule), the string match is used
instead of the returned or generated values.

   ab = (x.({qr/\d/} =SM) qr/\d/) S{$x}; #Will return a string

   cd = (y.{qr/\d/} qr/\d/) S{$y}; #Will return hash ref to an array ref

Likewise, =MO does MATCH_ONCE and =MMF does MATCH_MIN_FIRST.  These are
described in the Parse::Stallion documentation.

=head3 COMMENTS

Comments may be placed on lines after a hash ('#'):

    rule = (sub1 # comment
    sub2 #comment
    sub3) S{}
    # comment

=head3 PARSE_FORWARD

As in Parse::Stallion, a PARSE_FORWARD routine may be declared via
F{ sub {your routine} }F (or F[ followed by ]F).
A PARSE_BACKTRACK routine can follow via a B{ sub {...}}B.

=head1 VERSION

0.7

=head1 AUTHOR

Arthur Goldstein, E<lt>arthur@acm.orgE<gt>

=head1 ACKNOWLEDGEMENTS

Julio Otuyama

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-9 by Arthur Goldstein.  All Rights Reserved.

This module is free software. It may be used, redistributed and/or modified
under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)


=head1 SEE ALSO

example/calculator_ebnf.pl

t/ebnf_in.t in the test cases for examples.

Parse::Stallion
  
=cut
