package Parse::QTEDI;

# Author: Dongxu Ma <dongxu@cpan.org>

use 5.005;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $parser $DEBUG);
require Exporter;
@ISA = qw(Exporter);
@EXPORT    = qw();
@EXPORT_OK = qw($parser);

use Parse::RecDescent ();
use YAML::Syck ();

$VERSION = '0.19';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

# Global flags 
# unless undefined, report fatal errors
#$::RD_ERRORS = 1;
# unless undefined, also report non-fatal problems
#$::RD_WARN = 1;
# if defined, also suggestion remedies
$::RD_HINT = 1;
# if defined, also trace parsers' behaviour
#$::RD_TRACE = 1;
# if defined, generates "stubs" for undefined rules
#$::RD_AUTOSTUB = 1;
# if defined, appends specified action to productions
#$::RD_AUTOACTION = 1;

$::RD_DEBUG = $DEBUG ? 1 : 0;

my $grammar = do { local $/; <DATA> };
$parser = Parse::RecDescent::->new($grammar);

1;
__DATA__
# focus on:
# Level 1: class, namespace, typedef, function, enum, union
# Level 2: template, expression
# 
# which are relavant to make binding
# loop structure
# CAUTION: the biggest assert here is we are working on a _VALID_ header
begin          : <rulevar: local $stash = [] >
begin          : 
  loop(s) eof { print YAML::Syck::Dump($stash) } 
eof            : /^\Z/
# make sure function_pointer is IN FRONT OF function
# since function is compatible with function_pointer, unfortunately 
primitive_loop : 
    qt_macro(s) 
  | kde_macro(s) 
  | typedef(s) 
  | comment(s) 
  | enum(s) 
  | template(s) 
  | extern(s)  
  | namespace(s) 
  | class(s) 
  | function_pointer(s)
  | function(s) 
  | expression(s) 
# inside a class each primitive code block has to consider 
# accessibility keyword(s) in front of  
primitive_loop_inside_class : 
    qt_macro 
  | kde_macro 
  | typedef 
  | comment 
  | enum 
  | template 
  | extern 
  | namespace 
  | class   
  | function_pointer 
  | function 
  | expression 
loop           : 
    primitive_loop { push @$stash, @{$item[1]} }
  | 
# keywords
keywords         : 
    keyword_class    | keyword_typedef | keyword_comment 
  | keyword_template | keyword_enum 
keyword_class_optional : 
  'friend' | 'static' | 'mutable' 
keyword_class    : 
  keyword_class_optional(s?) ( 'class' | 'struct' | 'union' ) 
  { $return = [ $item[2], $item[1] ] } 
keyword_namespace: 'namespace'
keyword_typedef  : 'typedef'
keyword_comment  : '#'
keyword_template : 'template'
keyword_enum     : 'enum'
keyword_inside_expression : 
  'struct' | 'enum' | 'union' 
# primitive code blocks
comment   : 
  keyword_comment /.*?$/mio 
  { $return = { type => 'comment', value => $item[2] } } 
  { print STDERR $item[1], ": ", $item[2], "\n" if $::RD_DEBUG }
typedef   : 
  keyword_typedef 
  (   enum               { $return = $item[1] } 
    | class              { $return = $item[1] } 
    | function_pointer   { $return = $item[1] } 
    | /(?>[^;]+)/sio ';' { $return = $item[1] } 
  )  
  { $return = { type => 'typedef', body => $item[2] } }
  { print STDERR $item[1], ": ", $item[2], "\n" if $::RD_DEBUG }
enum      : 
  keyword_enum enum_name enum_body variables ';'
  { 
    $return = { type => 'enum' }; 
    $return->{name} = $item[2] if $item[2];
    $return->{value} = $item[3] if $item[3];
    $return->{variable} = $item[4] if $item[4];
    unless($item[3]) { 
        # no enum body, possibly inside typedef or forward decl
        # split variables from enum_name
        my @v = split /(?<!,)\s+(?!,)/, $item[2];
        if (@v > 1) {
            $return->{variable} = pop @v;
            $return->{name}     = join(" ", @v);
        }
    }
  }  
  { print STDERR $item[1], ": ", join(" ", $item[2], join(" ", @{$item[3]}), $item[4]), "\n" 
        if $::RD_DEBUG }
# make sure it has no other structure delimiters
# special handle for C-stype enum/struct/union expression
expression: 
    (   class_accessibility_content 
      | keyword_class | keyword_typedef | keyword_comment 
      | keyword_template 
    ) <commit> <reject>
  | keyword_inside_expression <commit> next_brace_or_semicolon ';' 
    { 
      $return = { type => 'expression', 
        value => join(" ", $item[1], $item[3]) } 
    } 
    { print STDERR "expression: ", $return, "\n" if $::RD_DEBUG } 
  | expression_body ';'
    { $return = { type => 'expression', value => $item[1] } } 
    { print STDERR "expression: ", $item[1], "\n" if $::RD_DEBUG }
# container code blocks
template : 
  keyword_template '<' template_typename '>' template_body
  { 
    $return = { type => 'template', body => $item[5] };
    $return->{typename} = $item[3] if $item[3];
  } 
  { print STDERR $item[1], ": ", 
        join(" ", @item[2 .. 5]), "\n" if $::RD_DEBUG }
extern   : 
    'extern' '"C"' '{' namespace_body(s?) '}' 
    { $return = { type => 'extern', subtype => 'C', body => [] }   }
    { foreach my $a (@{$item[4]}) { push @{$return->{body}}, @$a } }
    { print STDERR "extern: ", 
          join(" ", $item[2], $item[4]), "\n" if $::RD_DEBUG } 
  | 'extern' 
    (   class 
        { $return = { subtype => 'class',      body => $item[1] } }
      | enum  
        { $return = { subtype => 'enum',       body => $item[1] } } 
      | function 
        { $return = { subtype => 'function',   body => $item[1] } } 
      | expression 
        { $return = { subtype => 'expression', body => $item[1] } } ) 
    { $return = $item[2]; $return->{type} = 'extern' } 
    { print STDERR "extern: ", 
          join(" ", $return->{type}, $return->{subtype}), "\n" if $::RD_DEBUG } 
namespace: 
  keyword_namespace namespace_name '{' namespace_body(s?) '}' ( ';' | )
  { $return = { type => 'namespace', name => $item[2], body => [] } }
  { foreach my $a (@{$item[4]}) { push @{$return->{body}}, @$a }    }
  { print STDERR "namespace: ", $item[2], "\n" if $::RD_DEBUG }
class    : 
  keyword_class class_name class_inheritance class_body class_attribute variables ';'
  { 
    $return = { type => $item[1][0], name => $item[2] };
    $return->{property} = $item[1][1] if @{$item[1][1]};
    $return->{inheritance} = $item[3] if $item[3];
    $return->{body} = $item[4] if $item[4];
    $return->{attribute} = $item[5] if $item[5];
    $return->{variable} = $item[6] if $item[6];
    unless($item[4]) { 
        # no class body, possibly inside typedef or forward decl
        # split variables from enum_name
        my @v = split /(?<!,)\s+(?!,)/, $item[2];
        if (@v > 1) {
            $return->{variable} = pop @v;
            $return->{name}     = join(" ", @v);
        }
    }
  } 
  { print STDERR $item[1][0], ": ", 
        join(" ", @item[2 .. $#item-3]), "\n" if $::RD_DEBUG }
# a simple trap here 
# to prevent template function from being parsed as normal one
function : 
    keyword_template <commit> <reject>
  | class_accessibility <commit> <reject> 
  | function_header function_body
    { 
      $return = { type => 'function', %{$item[1]} }; 
      if ($item[2]) {
        push @{$return->{property}}, $item[2];
      }
    } 
    { print STDERR "function: ", $item[1]->{name}, "\n" if $::RD_DEBUG }
# QT-specific macros
qt_macro_1 : 
  'QT_BEGIN_HEADER' | 'QT_END_HEADER' | 'Q_OBJECT' | 'Q_GADGET' 
qt_macro_2 : 
  'QT_MODULE' | 'Q_FLAGS' | 'Q_DISABLE_COPY' | 
  'QDOC_PROPERTY' | 'Q_ENUMS' | 'Q_SETS' | 'Q_OVERRIDE' | 
  'Q_DECLARE_FLAGS' | 'Q_DECLARE_PRIVATE' | 'Q_DECLARE_TYPEINFO' | 
  'Q_DECLARE_METATYPE' | 'Q_DECLARE_BUILTIN_METATYPE' | 
  'Q_DECLARE_EXTENSION_INTERFACE' | 
  'Q_DECLARE_OPERATORS_FOR_FLAGS' | 'Q_DECLARE_SHARED' | 
  'Q_DECLARE_INTERFACE' | 'Q_DECLARE_ASSOCIATIVE_ITERATOR' | 
  'Q_DECLARE_MUTABLE_ASSOCIATIVE_ITERATOR' | 
  'Q_DECLARE_SEQUENTIAL_ITERATOR' | 
  'Q_DECLARE_MUTABLE_SEQUENTIAL_ITERATOR' | 
  'Q_DUMMY_COMPARISON_OPERATOR' 
qt_macro_3 : 
  'Q_PRIVATE_SLOT' | 'Q_PROPERTY' | 'Q_PRIVATE_PROPERTY' | 'Q_CLASSINFO' | 'Q_INTERFACES'
qt_macro_10: 
 'Q_INVOKABLE' 
qt_macro_99: 
  'Q_REQUIRED_RESULT' 
qt_macro : 
    qt_macro_1 ( ';' | )
    { $return = { type => 'macro', subtype => 1, name => $item[1] } } 
    { print STDERR $item[1], "\n" if $::RD_DEBUG } 
  | qt_macro_2 '(' next_end_bracket ')' ( ';' | )
    { $return = { type => 'macro', subtype => 2, name => $item[1], 
        value => $item[3] } } 
    { print STDERR join(" ", @item[1 .. 4]), "\n" if $::RD_DEBUG } 
  | qt_macro_3 '(' balanced_bracket(s) ')' ( ';' | )
    { $return = { type => 'macro', subtype => 3, name => $item[1], 
        values => join(" ", @{$item[3]}) } } 
    { print STDERR join(" ", $item[1 .. 2], @{$item[3]}, $item[4]), "\n" if $::RD_DEBUG } 
# KDE related
kde_macro_1  : 
  'K_DCOP' 
kde_macro_2  : 
  'K_SYCOCATYPE'
kde_macro_3  : 
  'K_FIXME_FIXME_FIXME' 
kde_macro_99 : 
  'KDE_DEPRECATED' | 'KDE_EXPORT' 
kde_macro : 
    kde_macro_1 ( ';' | )
    { $return = { type => 'macro', subtype => 1, name => $item[1] } } 
    { print STDERR $item[1], "\n" if $::RD_DEBUG } 
  | kde_macro_2 '(' next_end_bracket ')' ( ';' | )
    { $return = { type => 'macro', subtype => 2, name => $item[1], 
        value => $item[3] } } 
    { print STDERR join(" ", @item[1 .. $#item]), "\n" if $::RD_DEBUG } 
  | kde_macro_3 '(' balanced_bracket(s) ')' ( ';' | )
    { $return = { type => 'macro', subtype => 3, name => $item[1], 
        values => join(" ", @{$item[3]}) } } 
    { print STDERR join(" ", $item[1 .. 2], @{$item[3]}, $item[4]), "\n" if $::RD_DEBUG } 

# functional code blocks
# internal actions
# CAUTION: might get dirty string which contains \t\n
#          strip hard return
# FIXME: \015 for MSWin32
next_begin_brace : 
  /(?>[^\{]+)/sio     { ( $return = $item[1] ) =~ s/\n/ /go }
next_end_brace : 
  /(?>[^\}]+)/sio     { ( $return = $item[1] ) =~ s/\n/ /go }
next_begin_or_end_brace : 
  /(?>[^\{\}]+)/sio   { ( $return = $item[1] ) =~ s/\n/ /go }
next_brace_or_semicolon : 
  /(?>[^\{\}\;]+)/sio { ( $return = $item[1] ) =~ s/\n/ /go } 
next_begin_angle_bracket : 
  /(?>[^\<]+)/sio     { ( $return = $item[1] ) =~ s/\n/ /go }
next_end_angle_bracket : 
  /(?>[^\>]+)/sio     { ( $return = $item[1] ) =~ s/\n/ /go }
next_angle_bracket : 
  /(?>[^\<\>]+)/sio   { ( $return = $item[1] ) =~ s/\n/ /go }
next_begin_square_bracket : 
  /(?>[^\[]+)/sio     { ( $return = $item[1] ) =~ s/\n/ /go }
next_end_square_bracket : 
  /(?>[^\]]+)/sio     { ( $return = $item[1] ) =~ s/\n/ /go }
next_square_bracket : 
  /(?>[^\[\]]+)/sio   { ( $return = $item[1] ) =~ s/\n/ /go }
next_equals : 
  /(?>[^\=]+)/sio     { ( $return = $item[1] ) =~ s/\n/ /go }
next_dot : 
  /(?>[^\,]+)/sio     { ( $return = $item[1] ) =~ s/\n/ /go }
next_dot_or_end_brace : 
  /(?>[^\,\}]+)/sio   { ( $return = $item[1] ) =~ s/\n/ /go } 
next_begin_bracket : 
  /(?>[^\(]+)/sio     { ( $return = $item[1] ) =~ s/\n/ /go }
next_end_bracket : 
  /(?>[^\)]+)/sio     { ( $return = $item[1] ) =~ s/\n/ /go }
next_bracket_or_semicolon : 
  /(?>[^\(\)\;]+)/sio { ( $return = $item[1] ) =~ s/\n/ /go } 
next_begin_or_end_bracket : 
  /(?>[^\(\)]+)/sio   { ( $return = $item[1] ) =~ s/\n/ /go } 
next_bracket_or_brace_or_semicolon : 
  /(?>[^\(\)\{\}\;]+)/sio { ( $return = $item[1] ) =~ s/\n/ /go } 
next_bracket_or_brace_or_semicolon_or_equal : 
  /(?>[^\(\)\{\}\;\=]+)/sio { ( $return = $item[1] ) =~ s/\n/ /go } 
next_bracket_or_square_bracket_or_brace_or_semicolon_or_equal : 
  /(?>[^\(\)\{\}\[\]\;\=]+)/sio { ( $return = $item[1] ) =~ s/\n/ /go } 
next_semicolon : 
  /(?>[^\;]+)/sio     { ( $return = $item[1] ) =~ s/\n/ /go }
next_begin_brace_or_colon_or_semicolon : 
  /(?>[^\{\:\;]+)/sio { ( $return = $item[1] ) =~ s/\n/ /go }

balanced_bracket_next_token : 
    next_begin_or_end_bracket { $return = $item[1] } 
  | { $return = ''       } 
balanced_bracket : 
  balanced_bracket_next_token 
  ( '(' balanced_bracket(s) ')' 
      { $return = join(" ", $item[1], @{$item[2]}, $item[3]) } 
    | { $return = '' } ) 
    { $return = join(" ", @item[1 .. $#item]) } 
  | { $return = ''       } 

balanced_angle_bracket_next_token : 
    next_angle_bracket { $return = $item[1] } 
  | { $return = ''       } 
balanced_angle_bracket : 
  balanced_angle_bracket_next_token 
  ( '<' balanced_angle_bracket(s) '>' 
      { $return = join(" ", $item[1], @{$item[2]}, $item[3]) } 
    | { $return = '' } ) 
    { $return = join(" ", @item[1 .. $#item]) }
  | { $return = ''       } 
# expression related
# array declaration should be handled carefully
# FIXME: __attribute__()
expression_next_token : 
    next_bracket_or_square_bracket_or_brace_or_semicolon_or_equal 
    { $return = $item[1] }
  | { $return = ''       } 
array_dimention_next_token : 
    next_square_bracket { $return = $item[1] } 
  | { $return = ''       } 
expression_body : 
  expression_next_token 
  { $item[1] =~ m/\boperator\W?$/o ? undef : 1 } 
  array_dimention(s?) 
  expression_value(?) 
  { $return = join(" ", $item[1], @{$item[3]}, $item[4]) } 
array_dimention : 
  '[' (   next_square_bracket { $return = $item[1] } 
        | { $return = '' } ) ']' 
  { $return = join(" ", @item[1 .. 3]) } 
expression_value: 
  '=' ( '{' balanced_brace(s) '}' | next_semicolon ) 
  { $return = '= '. $item[2] }
# variable related
variables : next_semicolon { $return = $item[1] } | { $return = '' } 

# function related
# at least one '()' block should appear for a valid header
# trap other keywords to prevent mess
function_header       : 
    (   keyword_comment | keyword_class | keyword_enum 
      | keyword_typedef ) <commit> <reject>
  | ( qt_macro_10 | ) function_header_block(s) 
    { 
      $return->{name} = ''; 
      my $seen_function_name = 0; 
      foreach my $i (@{$item[2]}) { 
          if ($i->{_subtype} == 1) { 
              # attribute
              # stripped currently
              #$return->{name} .= " ". $i->{_value}; 
          } elsif ($i->{_subtype} == 2) { 
              # function name with params
              $seen_function_name = 1;
              $return->{name} .= $i->{_name};
              $return->{parameter} = $i->{_value} if 
                  @{$i->{_value}};
          } elsif ($i->{_subtype} == 3) { 
              # other macros
              push @{$return->{property}}, $i->{_value} if 
                  $i->{_value};
          } elsif ($i->{_subtype} == 4) {
              # const
              if ($i->{_value}) {
                  if ($seen_function_name) {
                      push @{$return->{property}}, $i->{_value};
                  }
                  else {
                      $return->{name} = $i->{_value}. ' '. $return->{name};
                  }
              }
          }
      } 
    } 
function_header_next_token : 
  next_bracket_or_brace_or_semicolon_or_equal 
    { $return = $item[1] } 
  | { $return = ''       } 

# function parameter process
# parse parameters and simply consume __attribute__ 
function_header_block : 
  (   /const\b/o
      { 
        #print STDERR "const\n";
        $return = { _subtype => 4, _value => 'const' };
      }
    | function_header_next_token 
      { $item[1] =~ m/\boperator\b/o ? 1 : undef } 
      ( '(' ')' { $return = '()' } | next_begin_bracket { $return = $item[1] } )
      '(' 
      ( function_parameters { $return = $item[1]; } | { $return = []; } ) 
      ')' 
      { 
        #print STDERR "operator\n";
        $return = { _subtype => 2, _name => $item[1].$item[3], }; 
        $return->{_value} = $item[5];
      } 
    | function_header_next_token 
      { $item[1] =~ m/^\s*throw\s*$/o ? 1 : undef } 
      '(' next_bracket_or_brace_or_semicolon ')'
      { 
        #print STDERR "throw\n";
        $return = { _subtype => 3, _value => 'throw('. $item[4]. ')' }
      }
    | function_header_next_token 
      { $item[1] =~ m/\_\_attribute\_\_\s*$/o ? 1 : undef } 
      '(' function_header_loop(s?) ')' 
      { 
        #print STDERR "__attribute__\n";
        $return = { _subtype => 1, 
                    _value   => join("", $item[1], $item[3], 
                                    @{$item[4]}, $item[5]) }
      } 
    | function_header_next_token 
      { $item[1] =~ m/^\:/o ? 1 : undef } 
      function_header_loop(s) 
      { $return = { _subtype => 0 } } 
    | function_header_next_token 
      '(' 
      ( function_parameters { $return = $item[1]; } | { $return = []; } ) 
      ')' 
      { 
        #print STDERR "name:$item[1]\n";
        $return = { _subtype => 2, _name => $item[1], };  
        $return->{_value} = $item[3];
      } 
  ) { $return = $item[1]; } 
  | function_macro_99(s?) 
    { 
      #print STDERR "property:", @{$item[1]}, "\n";
      $return = { _subtype => 3, _value => join("", @{$item[1]}) }
    } 
# TODO: loop in more elegant way
function_header_loop  : 
  (   function_header_next_token { $return = $item[1]; } 
    | { $return = ''; } 
  ) 
  (   '(' ')' { $return = '()'; } 
    | '(' function_header_loop(s?) ')' 
      { $return = join("", $item[1], @{$item[2]}, $item[3]) } 
    | { $return = '' } 
  ) 
  { $return = join("", @item[1 .. $#item]) } 

function_macro_99     : 
    'const' | qt_macro_99 | kde_macro_99 

function_parameters : 
    function_parameter_loop 

function_parameter_loop : 
    function_parameter 
    (   ',' function_parameter_loop { $return = $item[2] } 
      | { $return = [] } 
    ) 
    { $return = [ $item[1] ]; push @$return, @{$item[2]} if @{$item[2]} } 

function_parameter  : 
    function_parameter_declaration function_parameter_default_value(?) 
    { 
      $return = $item[1]; 
      $return->{default} = $item[2]->[0] if @{$item[2]}; 
    } 

function_parameter_declaration_next_token : 
    /(?>[^\,\=\(\)\<\>]+)/iso { ( $return = $item[1] ) =~ s/\n/ /go } 

function_parameter_declaration            : 
    (   function_parameter_declaration_next_token 
        { $return = $item[1]; } 
      | { $return = '';       } 
    ) 
    (   function_parameter_function_pointer 
        { $return = { subtype => 'fpointer', value => $item[1] }; } 
      | function_parameter_template_type 
        { $return = { subtype => 'template', value => $item[1] }; } 
      | function_parameter_array_pointer 
        { $return = { subtype => 'apointer', value => $item[1] }; }
      | { $return = { subtype => 'simple' }; } 
    ) 
    { 
      if ($item[2]->{subtype} eq 'simple') {
          $return = { name => $item[1], subtype => 'simple', };
      } elsif ($item[2]->{subtype} eq 'template') { 
          $return = { name => $item[1]. $item[2]->{value} };
          $return->{subtype} = 'template'; 
      } elsif ($item[2]->{subtype} eq 'fpointer') { 
          $return = $item[2]->{value};
          $return->{return}  = $item[1];
          $return->{subtype} = 'fpointer'; 
      } elsif ($item[2]->{subtype} eq 'apointer') {
          $return = $item[2]->{value};
          $return->{type} = $item[1]. $return->{type};
          $return->{subtype} = 'apointer';
      }
    } 

function_parameter_array_pointer : 
  '(' '&' function_parameter_declaration_next_token ')' 
  '[' /(?>[^\]]+)/iso ']' 
  { $return = { type => join("", @item[1,2,4..7]), name => $item[3] } }

function_parameter_template_type_next_token : 
    /(?>[^\<\>]+)/iso { ( $return = $item[1] ) =~ s/\n/ /go } 

function_parameter_template_type            : 
    '<' function_parameter_template_type_loop(s) '>' 
    (   function_parameter_declaration_next_token 
        { $return = $item[1]; } 
      | { $return = '';       } 
    ) 
    { 
      $return = join(" ", 
          join("", $item[1], join("", @{$item[2]}), $item[3]), 
          $item[4]); 
    } 

function_parameter_template_type_loop       : 
    (   function_parameter_template_type_next_token 
        { $return = $item[1]; } 
      | { $return = '';       } 
    ) 
    (   '<' function_parameter_template_type_loop '>' 
        { $return = join("", @item[1 .. 3]); } 
      | { $return = '';                      } 
    ) 
    { $return = join("", @item[1 .. 2]); } 

function_parameter_function_pointer_next_token : 
    /(?>[^\(\)]+)/iso { ( $return = $item[1] ) =~ s/\n/ /go } 

function_parameter_function_pointer            : 
    '(' function_parameter_function_pointer_loop ')' 
    { $item[2] ? 1 : undef }
    '(' function_parameter_loop ')' 
    function_parameter_function_pointer_const
    { 
      $return = { name => $item[2], parameter => $item[6], }; 
      push @{ $return->{property} },  $item[8] if $item[8]; 
    } 

# 'const' could be either return/param type attribute
# or function property
function_parameter_function_pointer_const      : 
    (   'const' { $return = 'const'; } 
      | { $return = ''; } 
    ) 
    { $return = $item[1]; } 

function_parameter_function_pointer_loop       : 
    (   function_parameter_function_pointer_next_token 
        { $return = $item[1]; }
      | { $return = '';       } 
    ) 
    (   function_parameter_function_pointer 
        { $return = $item[1]; } 
      | { $return = {};       } 
    ) 
    { 
      if (exists $item[2]->{name}) { 
          $return->{name}  = $item[2]->{name}; 
          $return->{parameter} = $item[2]->{parameter};
      }
      else {
          $return = $item[1];
      } 
    } 

function_parameter_default_value_next_token : 
    /(?>[^\(\'\"\)\,]+)/iso { ( $return = $item[1] ) =~ s/\n/ /go } 

function_parameter_default_value            : 
    '=' function_parameter_default_value_loop(s) 
    { $return = join("", @{$item[2]}); } 
    { print STDERR "default value:", $return, "\n" if $::RD_DEBUG; } 

function_parameter_default_value_loop_token_dispatch : 
    '(' ')' 
    { $return = '()'; } 
  | '" "' { $return = $item[1]; }
  | "' '" { $return = $item[1]; }
  | "(' ')" { $return = $item[1]; }
  | '(" ")' { $return = $item[1]; }
  | '(' function_parameter_default_value_loop2 ')' 
    { $return = join("", @item[1 .. 3]); } 
  | "'" /(?>[^\']*)/iso "'" { $return = join("", @item[1 .. 3]); } 
  | '"' /(?>[^\"]*)/iso '"' { $return = join("", @item[1 .. 3]); } 

function_parameter_default_value_loop2      : 
    (   function_parameter_default_value_next_token 
        { $return = $item[1]; } 
      | { $return = '';       } 
    ) 
    (   function_parameter_default_value_loop_token_dispatch 
        { $return = $item[1]; } 
      | ',' function_parameter_default_value_loop2 
        { $return = join("", @item[1 .. 2]); } 
      | { $return = '';                       } 
    ) 
    { $return = join("", @item[1 .. 2]); } 

function_parameter_default_value_loop       : 
    (   function_parameter_default_value_next_token 
        { $return = $item[1]; } 
      | { $return = '';       } 
    ) 
    (   function_parameter_default_value_loop_token_dispatch 
        { $return = $item[1]; } 
      | { $return = '';       } 
    ) 
    { $return = join('', @item[1 .. 2]); } 

function_body         : 
    ';' { $return = '' } 
  | '=' '0' ';' { $return = 'pure virtual' }
  | '{' balanced_brace(s) '}' ( ';' | ) { $return = '' }
balanced_brace_next_token : 
    next_begin_or_end_brace { $return = $item[1] }
  | { $return = ''       } 
balanced_brace            : 
    balanced_brace_next_token (  '{' balanced_brace(s) '}' | ) 
  | { $return = ''       }

# enum related
enum_name          : 
    next_brace_or_semicolon { $return = $item[1] }
  | { $return = ''       } 
# enum_unit(s /,/) _NOT_ work here
enum_body          : 
    '{' '}' { $return = [] }
  | '{' enum_unit(s) '}'
    { $return = [ grep { ref $_ } @{$item[2]} ] }
    #{ print STDERR "enum_body: ", join(" ", @{$item[2]}), "\n" if $::RD_DEBUG } 
  | { $return = ''       }
enum_unit          : 
    comment { $return = '' }
  | next_dot_or_end_brace ( ',' | )
    { $return = [ split /\s*=\s*/, $item[1] ] }
  #{ print STDERR "enum_unit: $return\n" if $::RD_DEBUG } 

# template related
template_typename  : 
    balanced_angle_bracket(s) { $return = join(" ", @{$item[1]}) } 
  | { $return = ''       }
# TODO: better way to handle template expression
template_body      : 
    class { $return = $item[1] }
  | function { $return = $item[1] } 
  | expression { $return = $item[1] } 

# class related
class_name          : 
    class_name_loop
class_name_next_token : 
    next_begin_brace_or_colon_or_semicolon { $return = $item[1] } 
  | { $return = '' } 
class_name_loop     : 
    class_name_next_token 
    (   '::' class_name_loop { $return = '::'.$item[2] } 
      | { $return = '' } ) 
    { $return = join("", $item[1], $item[2]) } 
    #{ print STDERR "class_name: ", $item[1], "\n" if $::RD_DEBUG } 
  | { $return = ''       } 
# FIXME: multiple inherit
class_inheritance   : 
    ':' next_begin_brace { $return = $item[2] }
    #{ print STDERR "class_inheritance: ", $item[2], "\n" if $::RD_DEBUG }
  | { $return = ''       }
# class_body_content(s?) _NOT_ work here
class_body          : 
    '{' '}' { $return = ''       }
  | '{' class_body_content(s) '}' 
    { $return = $item[2] } 
  | { $return = ''       } 
class_body_content  : 
    class_accessibility { $return = $item[1] } 
  | noop(s) { $return = { type => 'noop' } } 
  | primitive_loop_inside_class { $return = $item[1] } 
    #{ print STDERR "class_body_content: ", $return, "\n" if $::RD_DEBUG }
#  | { $return = ''       } 
#    #{ print STDERR "class_body_content: NULL\n" if $::RD_DEBUG } 
class_accessibility_loop : 
    ( class_accessibility_content { $return = $item[1] } | { $return = '' } ) qt_accessibility_content { $return = $item[1] ? join(' ', $item[1], $item[2]) : $item[2] }
  | class_accessibility_content
  | kde_accessibility_content 
class_accessibility : 
  class_accessibility_loop ':' 
  { $return = { type => 'accessibility', value => $item[1] } } 
qt_accessibility_content : 
  'Q_SIGNALS' | 'Q_SLOTS' | 'signals' | 'slots'
kde_accessibility_content: 
  'k_dcop' 
class_accessibility_content : 
  'public' | 'private' | 'protected' 
class_attribute: 
  /__attribute__\s*\(\((.+?)\)\)/io { $return = $1 } | { $return = '' }
noop :
  ';'

#namespace related
namespace_name : 
  next_begin_brace { $return = $item[1] } | { $return = '' } 
namespace_body : primitive_loop { $return = $item[1] }

#typedef related
function_pointer : 
  next_bracket_or_semicolon function_parameter_function_pointer ';'
  { 
    $return = $item[2]; 
    $return->{return} = $item[1]; 
    $return->{type}   = 'fpointer'; 
  } 
