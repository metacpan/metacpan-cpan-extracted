package Spp;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(spp repl eval_atom);

=head1 NAME

Spp - String prepare Parser

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Spp is a programming language, but also is parser tool of programming 
language.

    use Spp qw(spp repl);

    if ($ARGV[0]) { spp($ARGV[0]) } else { repl() }

then shell would ouput:

    This is Spp REPL implement with Perl5. type 'exit' to exit.
    >>>

=head1 EXPORT

    spp
    repl

=cut

use 5.020;
use Carp qw(croak);
use experimental qw(switch autoderef);
use Scalar::Util qw(looks_like_number);

use Spp::Tools;
use Spp::Optimizer   qw(opt_atom);
use Spp::AtomToValue qw(atom_to_value atoms_to_value);
use Spp::ValueToAtom qw(value_to_atom);
use Spp::AtomToStr   qw(atom_to_str chclass_to_str match_log_to_str);

#######################################################
## global variable
#######################################################
# Rule name
our $RULE = 'Spp';
# Rule Door of token name
our $DOOR = 'TOP';
# Boot context
our $MAIN = 'Main';
# false spp
our $FALSE = ['bool', 'false'];
# true spp
our $TRUE = ['bool', 'true'];
# nil spp
our $NIL = ['nil', 'nil'];
# Current context
our $CONTEXT = $MAIN;
# Symbol Table, use Hash
our $ST = { $MAIN => {} };
# context stack, use Array
our $CONTEXT_STACK = [ $MAIN ];
# current Call name
our $CALL = uuid();
# Call stack
our $CALL_STACK = [ $CALL ];
# current Block
our $BLOCK = uuid();
# Block stack
our $BLOCK_STACK = [ $BLOCK ];
# test case counter
our $TC = 0;
# Debug mode
our $DEBUG = 0;
# register Main as context name
$ST->{$MAIN}{$MAIN} = [ 'context', $MAIN ];
# restrain return table
$ST->{$CALL} = {};
# register Block in symbol table
$ST->{$BLOCK} = {};
# register ARGV to Symbol table
$ST->{$MAIN}{'ARGV'} = value_to_atom([ @ARGV ]);

###########################################
# built-in sub map
###########################################
our $Op_map = {
  '!='   => sub { eval_ne(@_)     },
  '+'    => sub { eval_add(@_)    },
  '+='   => sub { eval_inc(@_)    },
  '-'    => sub { eval_sub(@_)    },
  '<'    => sub { eval_lt(@_)     },
  '<<'   => sub { eval_push(@_)   },
  '<='   => sub { eval_le(@_)     },
  '='    => sub { eval_assign(@_) },
  '=='   => sub { eval_eq(@_)     },
  '>'    => sub { eval_gt(@_)     },
  '>='   => sub { eval_ge(@_)     },
  '>>'   => sub { eval_unshift(@_)},
  'and'  => sub { eval_and(@_)    },
  '&&'   => sub { eval_and(@_)    },
  'in'   => sub { eval_in(@_)     },
  'is'   => sub { eval_is(@_)     },
  'or'   => sub { eval_or(@_)     },
  '||'   => sub { eval_or(@_)     },
  '~~'   => sub { eval_match(@_)  },
};

our $Spp_map = {
  'begin'   => sub { eval_exprs(@_)   },
  '!='      => sub { eval_ne(@_)      },
  '+'       => sub { eval_add(@_)     },
  '+='      => sub { eval_inc(@_)     },
  '-'       => sub { eval_sub(@_)     },
  '<'       => sub { eval_lt(@_)      },
  '<='      => sub { eval_le(@_)      },
  '=='      => sub { eval_eq(@_)      },
  '>'       => sub { eval_gt(@_)      },
  '>='      => sub { eval_ge(@_)      },
  'and'     => sub { eval_and(@_)     },
  '&&'      => sub { eval_and(@_)     },
  'block'   => sub { ['str', $BLOCK]  },
  'bool'    => sub { eval_bool(@_)    },
  'break'   => sub { eval_break()     },
  'call'    => sub { ['str', $CALL]   },
  'case'    => sub { eval_case(@_)    },
  'context' => sub { eval_context(@_) },
  'def'     => sub { eval_def(@_)     },
  'defined' => sub { eval_defined(@_) },
  'delete'  => sub { eval_delete(@_)  },
  'end'     => sub { eval_end(@_)     },
  'to-i'    => sub { eval_to_i(@_)    },
  'exit'    => sub { exit()           },
  'exists'  => sub { eval_exists(@_)  },
  'for'     => sub { eval_for(@_)     },
  'if'      => sub { eval_if(@_)      },
  'load'    => sub { eval_load(@_)    },
  '~~'      => sub { eval_match(@_)   },
  'my'      => sub { eval_my(@_)      },
  'next'    => sub { eval_next()      },
  'not'     => sub { eval_not(@_)     },
  'ok'      => sub { eval_ok(@_)      },
  'or'      => sub { eval_or(@_)      },
  '||'      => sub { eval_or(@_)      },
  'uuid'    => sub { ['str', uuid()]  },
  'return'  => sub { eval_return(@_)  },
  'rule'    => sub { eval_rule(@_)    },
  'say'     => sub { eval_say(@_)     },
  'set'     => sub { eval_set(@_)     },
  'shift'   => sub { eval_shift(@_)   },
  'type'    => sub { eval_type(@_)    },
  'is'      => sub { eval_is(@_)      },
  '='       => sub { eval_assign(@_)  },
  'while'   => sub { eval_while(@_)   },
  '<<'      => sub { eval_shift(@_)   },
  '>>'      => sub { eval_unshift(@_) },
  'in'      => sub { eval_in(@_)      },
  'use'     => sub { eval_use(@_)     },
};

our $Host_map = {
  'fill'      => sub { fill_array(@_)  },
  'join'      => sub { host_join(@_)   },
  'len'       => sub { len(@_)         },
  'load_file' => sub { load_file(@_)   },
  'opt'       => sub { opt_atom(@_)    },
  'read-file' => sub { read_file(@_)   },
  'split'     => sub { host_split(@_)  },
  'substr'    => sub { host_substr(@_) },
  'to-json'   => sub { encode_json(@_) },
  'to-rule'   => sub { to_rule(@_)     },
  'write-file'=> sub { write_file(@_)  },
  'trim'      => sub { trim(@_)        },
  'rest'      => sub { rest(@_)        },
  'see'       => sub { see([@_])       },
  'zip'       => sub { host_zip(@_)    },
  'range'     => sub { host_range(@_)  },
};

sub get_token_atom {
  my $name = shift;
  for my $context (values $CONTEXT_STACK) {
    if (exists $ST->{$context}{$name}) {
      my $token = $ST->{$context}{$name};
      return $token->[1] if $token->[0] eq 'rule';
    }
  }
  error("token: <$name> not defined!");
}

sub match_atom {
  my ($atom, $cursor) = @_;
  my $match = _match_atom($atom, $cursor);
  my $flag = 'ok';
  $flag = '  ' if is_false($match);
  my $pos = $cursor->{POS};
  push $cursor->{LOG}, [ $flag, $atom, $pos ];
  return $match;
}

sub _match_atom {
  my ($atom, $cursor) = @_;
  my ($type, $value) = @{ $atom };
  given ($type) {
    when ('bool')    { $atom }
    when ('any')     { match_any($value, $cursor)     }
    when ('char')    { match_str($value, $cursor)     }
    when ('str')     { match_str($value, $cursor)     }
    when ('token')   { match_token($value, $cursor)   }
    when ('group')   { match_token($value, $cursor)   }
    when ('branch')  { match_branch($value, $cursor)  }
    when ('lbranch') { match_lbranch($value, $cursor) }
    when ('rept')    { match_rept($value, $cursor)    }
    when ('look')    { match_look($value, $cursor)    }
    when ('strs')    { match_strs($value, $cursor)    }
    when ('chclass') { match_chclass($value, $cursor) }
    when ('alias')   { match_alias($value, $cursor)   }
    when ('action')  { match_action($value, $cursor)  }
    when ('ctoken')  { match_ctoken($value, $cursor)  }
    when ('rtoken')  { match_rtoken($value, $cursor)  }
    when ('gtoken')  { match_gtoken($value, $cursor)  }
    when ('assert')  { match_assert($value, $cursor)  }
    when ('cclass')  { match_cclass($value, $cursor)  }
    default { error("Unknown atom type: $type to match") }
  }
}

sub match_ctoken {
  my ($name, $cursor) = @_;
  my $atom = get_token_atom($name);
  my $match = match_atom($atom, $cursor);
  return name_match($name, $match);
}

sub match_rtoken {
  my ($name, $cursor) = @_;
  my $atom = get_token_atom($name);
  my $pos_cache = $cursor->{POS};
  my $match = match_atom($atom, $cursor);
  if (is_match($match)) {
    my $str = $cursor->{STR};
    my $pos = $cursor->{POS};
    my $pos_len = $pos - $pos_cache;
    my $match_str = substr($str, $pos_cache, $pos_len);
    return $match_str;
  }
  return $FALSE;
}

sub match_alias {
  my ($ast, $cursor) = @_;
  my ($alias_name, $alias_atom) = @{ $ast };
  my $match = $FALSE;
  if ($alias_atom->[0] eq 'ctoken') {
    my $token_name = $alias_atom->[1];
    my $token_atom = get_token_atom($token_name);
    $match = match_atom($token_atom, $cursor);
  } else {
    $match = match_atom($alias_atom, $cursor);
  }
  return name_match($alias_name, $match);
}

sub match_gtoken {
  my ($name, $cursor) = @_;
  my $atom = get_token_atom($name);
  my $pos_cache = $cursor->{POS};
  my $match = match_atom($atom, $cursor);
  $cursor->{POS} = $pos_cache;
  return $TRUE if is_false($match);
  return $FALSE;
}

sub match_token {
  my ($atoms, $cursor) = @_;
  my $gather = $TRUE;
  foreach my $atom (values $atoms) {
    my $match = match_atom($atom, $cursor);
    return $match if is_false($match);
    $gather = gather_match($gather, $match);
  }
  return $gather;
}

# match branch, first match would return
sub match_branch {
  my ($branch, $cursor) = @_;
  my $pos_cache = $cursor->{POS};
  foreach my $atom (values $branch) {
    my $match = match_atom($atom, $cursor);
    if (is_match($match)) { return $match }
    $cursor->{POS} = $pos_cache;
  }
  return $FALSE;
}

sub match_lbranch {
  my ($branch, $cursor) = @_;
  my $pos_cache = $cursor->{POS};
  my $max_len = 0;
  my $max_match = $FALSE;
  foreach my $atom (values $branch) {
    my $match = match_atom($atom, $cursor);
    my $to_pos = $cursor->{POS};
    $cursor->{POS} = $pos_cache;
    next if is_false($match);
    # if match ok, get match str length
    my $match_str_len = $to_pos - $pos_cache;
    # if match str longest than have even matched length
    if ($match_str_len >= $max_len) {
      $max_len = $match_str_len;
      $max_match = $match;
    }
  }
  $cursor->{POS} += $max_len;
  return $max_match;
}

sub match_strs {
  my ($strs, $cursor) = @_;
  my $max_len = 0;
  my $max_str = $FALSE;
  foreach my $str (values $strs) {
    my $len = len($str);
    my $apply_str = apply_char($len, $cursor);
    next if $str ne $apply_str;
    if ($len >= $max_len) {
      $max_len = $len;
      $max_str = $str;
    }
  }
  # if not match ok, then Pos not change and return $FALSE
  $cursor->{POS} += $max_len;
  return $max_str;
}

sub match_look {
  my ($look, $cursor) = @_;
  my ($atom, $rept, $look_atom) = @{$look};
  my $gather = $TRUE;
  my $match_time = 0;
  my ($min_time, $max_time) = @{$rept};
  if ($match_time >= $min_time) {
    my $match = match_atom($look_atom, $cursor);
    if (is_match($match)) {
      return gather_match($gather, $match);
    }
  }
  while ($match_time != $max_time) {
    my $pos_cache = $cursor->{POS};
    my $match = match_atom($atom, $cursor);
    if (is_false($match)) {
      return $match if $match_time < $min_time;
      $cursor->{POS} = $pos_cache;
      my $look_match = match_atom($look_atom, $cursor);
      return $look_match if is_false($look_match);
      return gather_match($gather, $look_match);
    }

    $match_time += 1;
    $gather = gather_match($gather, $match);

    if ($match_time >= $min_time) {
      $pos_cache = $cursor->{POS};
      my $look_match = match_atom($look_atom, $cursor);
      if (is_match($look_match)) {
        return gather_match($gather, $look_match);
      }
      $cursor->{POS} = $pos_cache;
    }
  }
  return $FALSE;
}

sub match_rept {
  my ($atom_rept, $cursor) = @_;
  my $gather = $TRUE;
  my $match_time = 0;
  my ($atom, $rept) = @{$atom_rept};
  my ($min_time, $max_time) = @{$rept};
  while ($match_time != $max_time) {
    my $pos_cache = $cursor->{POS};
    my $match = match_atom($atom, $cursor);
    if (is_false($match)) {
      if ($match_time < $min_time) { return $match }
      $cursor->{POS} = $pos_cache;
      return $gather;
    } else {
      $match_time += 1;
      $gather = gather_match($gather, $match);
    }
  }
  return $gather;
}

sub match_action {
  my ($exprs, $cursor) = @_;
  my $atom = eval_atom($exprs);
  my ($type, $value) = @{ $atom };
  given ($type) {
    when ('nil')   { return $FALSE }
    when ('bool')  { return $atom  }
    when ('str')   { return match_str($value, $cursor)   }
    when ('array') { return match_array($value, $cursor) }
    default { error("Not implement action: $type")       }
  }
}

sub match_array {
  my ($array, $cursor) = @_;
  my $strs = [];
  if (all_is_spp_str($array)) {
    foreach my $str (values $array) {
      push $strs, $str->[1];
    }
    return match_strs($strs, $cursor);
  }
  error("Spp only implement match string array");
}

sub match_any {
  my ($value, $cursor) = @_;
  my $char = apply_char(1, $cursor);
  if (len($char) == 1) {
    $cursor->{POS}++;
    return $char;
  }
  return $FALSE;
}

sub match_str {
  my ($str, $cursor) = @_;
  my $str_len = len($str);
  my $apply_str = apply_char($str_len, $cursor);
  if ($str eq $apply_str) {
    $cursor->{POS} += $str_len;
    return $str;
  }
  return $FALSE;
}

sub match_chclass {
  my ($atom, $cursor) = @_;
  my $char = apply_char(1, $cursor);
  my $class_str = chclass_to_str($atom);
  if ($char =~ /$class_str/) {
    $cursor->{POS}++;
    return $char;
  }
  return $FALSE;
}

sub match_cclass {
  my ($cclass, $cursor) = @_;
  my $char = apply_char(1, $cursor);
  if ($char =~ /$cclass/) {
    $cursor->{POS}++;
    return $char;
  }
  return $FALSE;
}

sub bool {
  my $x = shift;
  return $TRUE if $x;
  return $FALSE;
}

sub match_assert {
  my ($str, $cursor) = @_;
  given ($str) {
    when ('^') { bool($cursor->{POS} == 0) }
    when ('$') { bool($cursor->{POS} >= $cursor->{LEN}) }
    when ('^^') {
      return $TRUE if apply_char(-1, $cursor) =~ /\n/;
      return $TRUE if $cursor->{POS} == 0;
      return $FALSE;
    }
    when ('$$') {
      return $TRUE if apply_char(1, $cursor) =~ /\n/;
      return $TRUE if $cursor->{POS} >= $cursor->{LEN};
      return $FALSE;
    }
    default { error("Unknown assert str: $str") }
  }
}

sub match_rule {
  my ($rule, $match_str) = @_;
  if ( trim($match_str) eq '') { return [] }
  my $cursor = create_cursor($match_str);
  in_context($rule);
  my $door_atom = get_token_atom($DOOR);
  my $match = match_atom($door_atom, $cursor);
  # see $match;
  if (is_false($match)) {
    if ($match_str =~ /\n\n+/) {
      for my $sub_str (split /\n\n+/, $match_str) {
        my $sub_match = match_rule($rule, $sub_str);
        if (is_false($sub_match)) {
          say "error at:\n $sub_str";
        } else { say "ok .."; }
      }
    }
    # match_log_to_str($cursor);
  }
  out_context($rule);
  return $match;
}

sub in_context {
  my $context_name = shift;
  if (not (exists $ST->{$MAIN}{$context_name})) {
    $ST->{$MAIN}{$context_name} = ['context', $context_name];
    $ST->{$context_name} = {};
  }
  $CONTEXT = $context_name;
  unshift $CONTEXT_STACK, $context_name;
  return ['context', $context_name];
}

sub out_context {
  my $context_name = shift;
  if ($CONTEXT eq $context_name) {
    shift $CONTEXT_STACK;
    $CONTEXT = $CONTEXT_STACK->[0];
    return ['context', $context_name];
  }
  error("Could not end $context_name from $CONTEXT");
}

sub in_call {
  my $context_name = shift;
  unshift $CALL_STACK, $context_name;
  $CALL = $context_name;
  if (exists $ST->{$context_name}) {
    error("into exists block: $context_name");
  }
  $ST->{$context_name} = {};
  unshift $CONTEXT_STACK, $context_name;
  $CONTEXT = $context_name;
  return ['context', $context_name];
}

sub out_call {
  my $context_name = shift;
  shift $CALL_STACK;
  $CALL = $CALL_STACK->[0];
  if ($context_name eq $CONTEXT) {
    delete $ST->{$context_name};
    shift $CONTEXT_STACK;
    $CONTEXT = $CONTEXT_STACK->[0];
    return ['context', $context_name];
  }
  error("Out block $context_name != $CONTEXT");
}

sub in_block {
  my $context_name = shift;
  if (exists $ST->{$context_name}) {
    error("into exists block: $context_name");
  }
  $ST->{$context_name} = {};
  unshift $CONTEXT_STACK, $context_name;
  $CONTEXT = $context_name;
  $BLOCK = $context_name;
  unshift $BLOCK_STACK, $context_name;
  return ['context_name', $context_name];
}

sub out_block {
  my $context_name = shift;
  if ($context_name eq $CONTEXT) {
    delete $ST->{$context_name};
    shift $CONTEXT_STACK;
    shift $BLOCK_STACK;
    $CONTEXT = $CONTEXT_STACK->[0];
    $BLOCK = $BLOCK_STACK->[0];
    return ['context_name', $context_name];
  }
  error("Out block $context_name != $CONTEXT");
}

sub eval_local_declare {
  my ($sym, $value) = @_;
  my $name = $sym->[1];
  if (exists $ST->{$CONTEXT}{$name}) {
    error("Have been defined local symbol: $name");
  }
  $ST->{$CONTEXT}{$name} = $value;
  return $sym;
}

sub eval_multi_local_declare {
  my ($syms, $values) = @_;
  return $TRUE if len($syms) == 0;
  if (all_is_spp_sym($syms)) {
    for my $sym_value (values host_zip($syms, $values)) {
      my ($sym, $value) = @{$sym_value};
      eval_local_declare($sym, $value);
    }
    return ['list', $syms];
  }
  error("only could bind symbol");
}

sub eval_sym_assign {
  my ($sym, $value) = @_;
  my $name = $sym->[1];
  for my $context (values $CONTEXT_STACK) {
    if (exists $ST->{$context}{$name}) {
      $ST->{$context}{$name} = $value;
      return $sym;
    }
  }
  error("Assign undefined symbol: $name");
}

sub eval_syms_assign {
  my ($syms, $values) = @_;
  for my $sym_value (values host_zip($syms, $values)) {
    my ($sym, $value) = @{$sym_value};
    eval_sym_assign($sym, $value);
  }
  return ['list', $syms];
}

sub to_rule {
  my ($grammar_file, $rule_file) = @_;
  my $parse_str = read_file($grammar_file);
  my $match_ast = match_rule($RULE, $parse_str);
  if (is_match($match_ast)) {
    my $opt_ast = opt_atom($match_ast);
    write_file($rule_file, to_str($opt_ast));
    return $rule_file;
  }
  error("Could not transfer $grammar_file to rule");
}

sub get_hash_key_value {
  my ($hash, $look_key) = @_;
  if ($hash->[0] eq 'hash') {
    my $index = 0;
    for my $pair (values $hash->[1]) {
      my ($key, $value) = @{ $pair };
      return [$index, $value] if is_same($look_key, $key);
      $index++;
    }
    return 0;
  }
  error("Could not get key value escept Hash");
}

sub set_hash_key_value {
  # see [@_];
  my ($hash, $key, $value) = @_;
  my $index_value = get_hash_key_value($hash, $key, $value);
  # see $index_value;
  my $hash_value = $hash->[1];
  if ($index_value) {
    my $index = $index_value->[0];
    $hash_value->[$index][1] = $value;
  } else {
    push $hash_value, [[$key, $value]];
  }
  return ['hash', $hash_value ];
}

#########################################
# eval atom
#########################################

sub eval_atoms {
  my $atoms = shift;
  my $atoms_array = [];
  for my $atom (values $atoms) {
    push $atoms_array, eval_atom($atom);
  }
  return $atoms_array;
}

sub eval_atom {
  my $atom = shift;
  # see $atom;
  my ($type, $value) = @{ $atom };
  given ($type) {
    when ('exprs')  { return eval_exprs($value)  }
    when ('sym')    { return eval_sym($value)    }
    when ('string') { return eval_string($value) }
    when ('array')  { return eval_array($value)  }
    when ('hash')   { return eval_hash($value)   }
    when ('list')   { return eval_list($value)   }
    default { return $atom }
  }
}

sub eval_exprs {
  my $exprs = shift;
  return eval_atom($exprs) if is_match_atom($exprs);
  my $return_value = $TRUE;
  for my $expr (values $exprs) {
    $return_value = eval_atom($expr);
    last if $ST->{$CALL}{':return'} == 1;
    last if $ST->{$BLOCK}{':next'} == 1;
    last if $ST->{$BLOCK}{':break'} == 1;
  }
  return $return_value;
}

# if exists sym records, return its value
# else should return symbol itself
sub eval_sym {
  my $name = shift;
  for my $context (values $CONTEXT_STACK) {
    if (exists $ST->{$context}{$name}) {
      return $ST->{$context}{$name};
    }
  }
  return ['sym', $name];
}

sub eval_string {
  my $atoms = shift;
  my $values = eval_atoms($atoms);
  my $strs = [];
  for my $value (values $values) {
    if ($value->[0] eq 'str') {
      push $strs, $value->[1];
    } else {
      push $strs, atom_to_str($value);
    }
  }
  return ['str', host_join($strs)];
}

sub eval_array {
  my $atoms = shift;
  my $values = [];
  for my $atom (values $atoms) {
    push $values, eval_atom($atom);
  }
  return ['array', $values];
}

sub eval_hash {
  my $pairs = shift;
  my $hash_value = [];
  for my $pair (values $pairs) {
    my $pair_value = eval_atoms($pair);
    push $hash_value, $pair_value;
  }
  return ['hash', $hash_value ];
}

sub eval_list {
  my $atoms = shift;
  my $op_atom = $atoms->[1];
  if (len($atoms) == 3 and $op_atom->[0] eq 'sym') {
    my $op_name = $op_atom->[1];
    if (exists $Op_map->{$op_name}) {
      my $op_call = $Op_map->{$op_name};
      if (is_func($op_call)) {
        my $args = [$atoms->[0], $atoms->[-1]];
        return $op_call->($args);
      }
    }
  }
  # tail if (return 1 if 1)
  if (is_same($atoms->[-2], ['sym','if'])) {
    my $cond_expr = $atoms->[-1];
    return $FALSE if is_false(eval_atom($cond_expr));
    my $true_expr = subarray($atoms, 0, -3);
    return eval_list($true_expr);
  }

  my $head_atom = $atoms->[0];
  if ($head_atom->[0] eq 'sym') {
    my $name = $head_atom->[1];
    if (exists $Spp_map->{$name}) {
      my $eval_call = $Spp_map->{$name};
      if (is_func($eval_call)) {
        my $args = rest($atoms);
        $args = $args->[0] if len($args) == 1;
        return $eval_call->($args);
      }
    }

    if (exists $Host_map->{$name}) {
      my $host_call = $Host_map->{$name};
      if (is_func($host_call)) {
        my $args = eval_atoms(rest($atoms));
        # see $args;
        my $values = atoms_to_value($args);
        my $return_value = $host_call->(@{$values});
        return value_to_atom($return_value);
      }
    }
  }

  # user defined method
  my $head_value = eval_atom($head_atom);
  if ($head_value->[0] eq 'lambda' ) {
    my $lambda_exprs = $head_value->[1];
    my $args = eval_atoms(rest($atoms));
    return call_lambda($lambda_exprs, $args);
  }

  # call other package method (context.method values)
  if ($head_value->[0] eq 'context') {
    # see $atoms;
    if ( is_same($atoms->[1], ['dot', '.']) ) {
      my $context = $head_value->[1];
      my $args = subarray($atoms, 2, -1);
      in_context($context);
      my $return_value = eval_list($args);
      out_context($context);
      return $return_value;
    }
  }

  my $args = eval_atoms(rest($atoms));
  if ($head_value->[0] eq 'str') {
    # str call use str itself
    my $value = $head_value->[1];
    return call_str($value, $args);
  }
  if ($head_value->[0] eq 'array') {
    # array_call use ['array', ...]
    return array_call($head_value, $args);
  }
  if ($head_value->[0] eq 'hash') {
    # hash call use ['hash', ...]
    return call_hash($head_value, $args);
  }
  my $head_value_str = to_str($head_value);
  error("Have not implement ($head_value_str ..)");
}

# call user defined sub or sub interface
sub call_lambda {
  my ($lambda_exprs, $real_args) = @_;
  my ($formal_args, $exprs) = @{$lambda_exprs};
  my $context = uuid();
  in_call($context);
  eval_multi_local_declare($formal_args, $real_args);
  my $return_value = eval_exprs($exprs);
  out_call($context);
  return $return_value;
}

sub call_str{
  my ($str, $nums) = @_;
  if ($nums->[0][0] eq 'int') {
    my $index = $nums->[0][1];
    if (len($nums) == 1) {
      my $index_char = substr($str, $index, 1);
      return $NIL if $index_char eq '';
      return ['str', substr($str, $index, 1)];
    }
    if (all_is_spp_int($nums)) {
      my $to_index = $nums->[1][1];
      my $str_len = $to_index - $index + 1;
      if ($to_index < 0) {
        $str_len = len($str) + $to_index + 1 - $index;
      }
      return ['str', substr($str, $index, $str_len)];
    }
  }
  error("syntax error str call");
}

# (array 1) (array 1 2) (array 2 -3) (array [1 2]
sub array_call {
  my ($array, $nums) = @_;
  # see $nums;
  # (array 1)
  if ($nums->[0][0] eq 'int') {
    my $index = $nums->[0][1];
    my $array_value = $array->[1];
    if (len($nums) == 1) {
      my $element = $array_value->[$index];
      return $element if $element;
      return $NIL;
    }
    # (array 1 2) (array 1 -2)
    if (len($nums) == 2 and all_is_spp_int($nums)) {
      my $to_index = $nums->[1][1];
      my $len_array = $to_index - $index + 1;
      if ($to_index < 0) {
        $len_array = len($array_value) + $to_index + 1 + $index;
      }
      my $elements = subarray($array_value, $index, $len_array);
      return $NIL if $elements eq '';
      return ['array', $elements];
    }
  }
  # (array [1 2]) => array[1][2]
  if ($nums->[0][0] eq 'array') {
    my $index_array = $nums->[0][1];
    if (all_is_spp_int($index_array)) {
      my $indexs = atoms_to_value($index_array);
      my $array_value = [ @{$array} ];
      for my $index (values $indexs) {
        if ($array_value->[0] eq 'array') {
          $array_value = $array_value->[1];
          $array_value = $array_value->[$index];
        } else {
          return $NIL;
        }
      }
      return $array_value;
    }
  }
}

# hash call (hash key) (hash key-one key-two)
sub call_hash {
  my ($hash_atom, $keys) = @_;
  # make a copy
  my $hash = [ @{$hash_atom} ];
  for my $key (values $keys) {
    if ($hash->[0] eq 'hash') {
      my $index_hash = get_hash_key_value($hash, $key);
      $hash = $index_hash->[1] if $hash;
    } else {
      return $NIL;
    }
  }
  return $hash;
}

####################################
# eval_list Spp function map
####################################

sub eval_ne {
  my $args = shift;
  my $eq_bool = eval_eq($args);
  return $FALSE if is_same($eq_bool, $TRUE);
  return $TRUE;
}

sub eval_add {
  my $args = shift;
  my $atoms = eval_atoms($args);
  my $values = [ map { $_->[1] } @{$atoms} ];
  if (all_is_spp_str($atoms)) {
    return ['str', host_join($values)];
  }
  if (all_is_spp_int($atoms)) {
    return ['int', host_sum($values)];
  }
  if (all_is_spp_array($atoms)) {
    return ['array', host_concat($values) ];
  }
}

sub eval_inc {
  my $args = shift;
  my $sym = $args->[0];
  if ($sym->[0] eq 'sym') {
    my $atoms = eval_atoms($args);
    my $add_value = eval_add($atoms);
    return eval_sym_assign($sym, $add_value);
  }
  error("inc syntax error");
}

sub eval_sub {
  my $args = shift;
  my $atoms = eval_atoms($args);
  if (all_is_spp_int($atoms)) {
    my $values = atoms_to_value($atoms);
    my $value = $values->[0];
    for my $num (values rest($values)) {
      $value = $value - $num;
    }
    return value_to_atom($value);
  }
  error(" - only implement int")
}

sub eval_lt {
  my $args = shift;
  my $values = eval_atoms($args);
  if (all_is_spp_int($values)) {
    my $first_num = $values->[0][1];
    for my $int (values rest($values)) {
      return $FALSE if $first_num >= $int->[1];
    }
    return $TRUE;
  }
  error("(> ..) only implement int");
}

sub eval_le {
  my $args = shift;
  return $TRUE if is_same($FALSE, eval_gt($args));
  return $FALSE;
}

sub eval_eq {
  my $atoms = shift;
  my $values = eval_atoms($atoms);
  my $first_value = $values->[0];
  for my $value (values rest($values)) {
    next if is_same($value, $first_value);
    return $FALSE;
  }
  return $TRUE;
}

sub eval_gt {
  my $args = shift;
  my $values = eval_atoms($args);
  if (all_is_spp_int($values)) {
    my $first_num = $values->[0][1];
    for my $int_atom (values rest($values)) {
      return $FALSE if $first_num <= $int_atom->[1];
    }
    return $TRUE;
  }
  error("compare >= only implement int");
}

sub eval_ge {
  my $args = shift;
  return $TRUE if is_same($FALSE, eval_lt($args));
  return $FALSE;
}

sub eval_and {
  my $atoms = shift;
  for my $atom (values $atoms) {
    return $FALSE if is_fail(eval_atom($atom));
  }
  return $TRUE;
}

sub eval_bool {
  my $atom = shift;
  my $value = eval_atom($atom);
  return $FALSE if is_fail($value);
  return $TRUE;
}

sub eval_break {
  $ST->{$BLOCK}{':break'} = 1;
  return $TRUE;
}

sub eval_case {
  my $atoms = shift;
  my $case_atom = $atoms->[0];
  my $case_value = eval_atom($case_atom);
  my $case_exprs = rest($atoms);
  for my $branch (values $case_exprs) {
    if ($branch->[0] eq 'list') {
      my $branch_exprs = $branch->[1];
      if (is_same($branch_exprs->[0], ['sym','when'])) {
        my $cond_atom = $branch_exprs->[1];
        if (is_same($case_value, $cond_atom)) {
          my $true_exprs = subarray($branch_exprs, 2, -1);
          return eval_exprs($true_exprs);
        }
      }
      if ( is_same($branch_exprs->[0], ['sym','else']) ) {
        my $true_exprs = subarray($branch_exprs, 1, -1);
        return eval_exprs($true_exprs);
      }
    }
  }
  return $FALSE;
}

sub eval_context {
  my $atom = shift;
  # (context) return current CONTEXT
  return $CONTEXT if len($atom) == 0;
  my $context = eval_atom($atom);
  my $type_str = type($context);
  # if is sym or existed context
  if (in($type_str, ['sym', 'context'])) {
    my $context_name = $context->[1];
    return in_context($context_name);
  }
  error("(context .. ) syntax error");
}

sub eval_def {
  my $atoms = shift;
  my $def_name = $atoms->[0];
  if ($def_name->[0] eq 'sym') {
    my $lambda_exprs = eval_lambda(rest($atoms));
    return eval_local_declare($def_name, $lambda_exprs);
  }
  if ($def_name->[0] eq 'list') {
    my $lambda_exprs = eval_lambda($atoms);
    return $lambda_exprs;
  }
  error("define syntax (#{atoms})");
}

sub eval_lambda {
  my $atoms = shift;
  if (len($atoms) < 2) { error('define accept 2 argment') }
  my $lambda_exprs = rest($atoms);
  if (len($atoms) == 0) { error('define accept 1 exprssion') }
  my $head_atom = $atoms->[0];
  if ($head_atom->[0] eq 'list') {
    my $args = $head_atom->[1];
    if (len($args) == 0) {
      return ['lambda', [[], $lambda_exprs]];
    }
    if (all_is_spp_sym($args)) {
      return ['lambda', [$args, $lambda_exprs]];
    }
    error("lambda args should is symbols");
  }
  error("lambda args should is list");
}

sub eval_defined {
  my $atom = shift;
  # (exists symbol): if it have been defined
  if ($atom->[0] eq 'sym') {
    my $name = $atom->[1];
    for my $context (values $CONTEXT_STACK) {
      return $TRUE if exists $ST->{$context}{$name};
    }
    return $FALSE;
  }
  error("Symtax error: (defined ..)");
}

sub eval_delete {
  my $args = shift;
  if (is_match_atoms($args)) {
    my $eval_atoms = eval_atoms($args);
    my ($atom, $key) = @{ $eval_atoms };
    # (delete hash key)
    if ($atom->[0] eq 'hash') {
      my $hash_value = $atom->[1];
      my $new_hash_value = [];
      for my $value (values $hash_value) {
        next if is_same($key, $value->[0]);
        push $new_hash_value, $value;
      }
      return ['hash', $new_hash_value];
    }
    if ($atom->[0] eq 'array') {
      my $array_value = $atom->[1];
      my $new_array_value = [];
      for my $value (values $array_value) {
        next if is_same($key, $value);
        push $new_array_value, $value;
      }
      return ['array', $new_array_value];
    }
  }
  # (delete symbol) => undefined
  if ($args->[0] eq 'sym') {
    my $name = $args->[1];
    for my $context (values $CONTEXT_STACK) {
      if (exists $ST->{$context}{$name}) {
        delete $ST->{$context}{$name};
        return $TRUE;
      }
    }
    return $FALSE;
  }
  error("Spp only implement delete symbol or hash key");
}

sub eval_end {
  my $atom = shift;
  if ($atom->[0] eq 'sym') {
    if ($CONTEXT eq $atom->[1]) {
      return out_context($CONTEXT);
    }
    error("out context is not $CONTEXT")
  }
  my $atom_type = type($atom);
  error("Syntax of (end ..): not context $atom_type");
}

sub eval_to_i {
  my $atom = shift;
  my $eval_atom = eval_atom($atom);
  if ($atom->[0] eq 'str') {
    if (looks_like_number($atom->[1])) {
      return ['int', 0 + $atom->[1] ];
    }
    my $value = $atom->[1];
    error("could not transfer str: $value to number");
  }
  return $atom if $atom->[0] eq 'int';
  my $type = type($atom);
  error("could not transfer $type type to number"); 
}

sub eval_exists {
  my $atom = shift;
  if ($atom->[0] eq 'str') {
    return $TRUE if -e $atom->[1];
    return $FALSE;
  }
  my $atoms = eval_atoms($atom);
  my ($hash_atom, $key) = @{$atoms};
  if ($hash_atom->[0] eq 'hash') {
    return $TRUE if get_hash_key_value($hash_atom, $key);
    return $FALSE;
  }
}

# (for x in array (next if (x eq 2)))
sub eval_for {
  my $atoms = shift;
  if (len($atoms) < 4) {
    error("syntax error for: args less 4");
  }
  my ($var, $in, $atom, @exprs) = @{ $atoms };
  my $exprs = [ @exprs ];
  if (is_same($in, ['sym','in'])) {
    my $eval_atom = eval_atom($atom);
    if ($var->[0] eq 'sym' and $eval_atom->[0] eq 'array') {
      my $array_value = $eval_atom->[1];
      return eval_for_array($var, $array_value, $exprs);
    }
    # (for (key value) in hash (do sth))
    if ($var->[0] eq 'list' and $eval_atom->[0] eq 'hash') {
      my $pair = $var->[1];
      my $hash_value = $eval_atom->[1];
      if (all_is_spp_sym($pair)) {
        return eval_for_hash($pair, $hash_value, $exprs);
      }
    }
  }
  error('for syntax error ..');
}

sub eval_for_array {
  my ($var, $array, $exprs) = @_;
  my $return_value = $TRUE;
  for my $element (values $array) {
    my $context = uuid();
    in_block($context);
    eval_local_declare($var, $element);
    $return_value = eval_exprs($exprs);
    if ($ST->{$CALL}{':return'} == 1) {
      out_block($context);
      return $return_value;
    }
    if ($ST->{$CONTEXT}{':break'} == 1) {
      out_block($context);
      last;
    }
    out_block($context);
  }
  return $return_value;
}

# (for x y in hash (do sth))
# hash is saved use perl built-hash
sub eval_for_hash {
  my ($var_pair, $hash, $exprs) = @_;
  my $return_value = $TRUE;
  # Spp hash implement with Perl array
  for my $pair (values $hash) {
    my $context = uuid();
    in_block($context);
    eval_multi_local_declare($var_pair, $pair);
    $return_value = eval_exprs($exprs);
    if ($ST->{$CALL}{':return'} == 1) {
      out_block($context);
      return $return_value;
    }
    if ($ST->{$CONTEXT}{':break'} == 1) {
      out_block($context);
      last;
    }
    out_block($context);
  }
  return $return_value;
}

sub eval_if {
  my $atoms = shift;
  if (len($atoms) < 2 ) {
    error("if syntax error: elements < 2");
  }
  my $cond_expr = $atoms->[0];
  my $true_atoms = [ $atoms->[1] ];
  my $index = 2;
  while ($index < len($atoms)) {
    my $atom = $atoms->[$index];
    if (is_same($atom, ['sym','elsif'])) {
      if (is_true(eval_bool($cond_expr))) {
        return eval_exprs($true_atoms);
      }
      my $if_exprs = subarray($atoms, $index+1, -1);
      return eval_if($if_exprs);
    }
    if (is_same($atom,['sym','else'])) {
      if (is_true(eval_bool($cond_expr))) {
        return eval_exprs($true_atoms);
      }
      my $else_atoms = subarray($atoms, $index+1, -1);
      return eval_exprs($else_atoms);
    } else {
      push($true_atoms, $atom);
      $index++;
    }
  }
  return $FALSE if is_false(eval_bool($cond_expr));
  return eval_exprs($true_atoms);
}

sub eval_use {
  my $atom = shift;
  my $file = $atom->[1];
  if (is_str($file)) {
    my $file_name = get_spp_file($file);
    my $parse_str = read_file($file_name);
    my $match_ast = match_rule($RULE, $parse_str);
    if (is_match($match_ast)) {
      eval_atom(opt_atom($match_ast));
      return $TRUE;
    }
  }
  error("Load only could accept file name");
}

sub eval_match {
  my $args = shift;
  my $atoms = eval_atoms($args);
  my ($match_str, $rule) = @{ $atoms };
  my $str_type = $match_str->[0];
  my $rule_type = $rule->[0];
  if ($str_type eq 'str') {
    my $str = $match_str->[1];
    my $rule_str = $rule->[1];
    if ($rule_type eq 'str') {
      return $TRUE if $str =~ /$rule_str/;
      return $FALSE;
    }
    if ($rule_type eq 'rule') {
      my $cursor = create_cursor($str);
      my $match = match_atom($rule_str, $cursor);
      return $FALSE if is_false($match);
      return value_to_atom($match);
    }
    if ($rule_type eq 'context') {
      my $match = match_rule($rule_str, $str);
      return $FALSE if is_false($match);
      return value_to_atom($match);
    }
  }
  error("$str_type Could not ~~ $rule_type");
}

sub eval_my {
  my $atoms = shift;
  if (is_match_atom($atoms)) {
    # say 'it is match atom';
    # (my x)
    if ($atoms->[0] eq 'sym') {
      my $sym = $atoms;
      return eval_local_declare($sym, $NIL);
    }
    # (my (x y z))
    if ($atoms->[0] eq 'list') {
      my $syms = $atoms->[1];
      my $values = fill(len($syms), $NIL);
      return eval_multi_local_declare($syms, $values);
    }
  }

  if (is_match_atoms($atoms)) {
    # (my x 1)
    my $sym = $atoms->[0];
    if ($sym->[0] eq 'sym') {
      my $value = eval_atom($atoms->[1]);
      return eval_local_declare($sym, $value);
    }
    # (my (x y z) [1 2])
    if ( $sym->[0] eq 'list' ) {
      my $syms = $sym->[1];
      my $array = eval_atom($atoms->[1]);
      # see $array;
      if ($array->[0] eq 'array') {
        my $values = $array->[1];
        return eval_multi_local_declare($syms, $values);
      }
      error("my value not array: $array");
    }
  }
  error("my syntax error: { atoms_to_strs(atoms) }");
}

sub eval_next {
  $ST->{$BLOCK}{':next'} = 1;
  return $TRUE;
}

sub eval_not {
  my $atom = shift;
  return $TRUE if is_false(eval_bool($atom));
  return $FALSE;
}

sub eval_ok {
  my $args = shift;
  my ($expr, $expect) = @{$args};
  my $expr_str    = atom_to_str($expr);
  my $expect_str  = atom_to_str($expect);
  my $message_str = "$expr_str == $expect_str";
  # see $expr;
  my $expr_get    = eval_atom($expr);
  my $expect_get  = eval_atom($expect);
  $TC++;
  if ( is_same($expr_get, $expect_get) ) {
    say("ok $TC - $message_str");
  } else {
    say("not $TC - $message_str");
    my $expr_get_str = atom_to_str($expr_get);
    say("get: $expr_get_str expect: $expect_str");
  }
  return $TRUE;
}

sub eval_or {
  my $atoms = shift;
  for my $atom (values $atoms) {
    next if is_fail(eval_atom($atom));
    return $TRUE;
  }
  return $FALSE;
}

sub eval_return {
  my $atom = shift;
  $ST->{$CALL}{':return'} = 1;
  return eval_atom($atom);
}

# add rule value to symbol table
sub eval_rule {
  my $args = shift;
  my $atoms = eval_atoms($args);
  my ($name, $rule) = @{ $atoms };
  if ($name->[0] eq 'sym' and $rule->[0] eq 'rule') {
    return eval_local_declare($name, $rule);
  }
  error("Syntax error: (rule .. )");
}

sub eval_say {
  my $atom = shift;
  say atom_to_str(eval_atom($atom));
  return $TRUE;
}

# (set hash key value)
# only support hash set
sub eval_set {
  my $args = shift;
  if (len($args) < 3) {
    error("(set syntax error: argument less than 3)");
  }
  my $atoms = eval_atoms($args);
  my $value = $atoms->[-1];
  my $hash = $atoms->[0];
  my $keys = subarray($atoms,1,-2);
  my $key = $keys->[0];
  if ($hash->[0] eq 'hash') {
    # (set hash key value)
    if (len($keys) == 1) {
      return set_hash_key_value($hash, $key, $value);
    }
    # (set hash key1 key2 value)
    if (len($keys) == 2) {
      my $tail_key = $keys->[-1];
      my $index_value = get_hash_key_value($hash, $key);
      my $sub_value = ['hash',[[$tail_key, $value]]];
      if ($index_value) {
        my ($index, $sub_hash) = @{ $index_value };
        if ($sub_hash->[0] eq 'hash') {
          $sub_value = set_hash_key_value($sub_hash, $tail_key, $value);
        }
        return set_hash_key_value($hash, $key, $sub_value);
      } else {
        my $hash_value = $hash->[1];
        push $hash_value, [[ $key, $sub_value ]];
        return ['hash', $hash_value];
      }
    }
  } else {
    error("Spp only implement set <Hash> value");
  }
}

sub eval_shift {
  my $sym = shift;
  my $array = eval_atom($sym);
  my $array_type = type($array);
  if ($array->[0] eq 'array') {
    my $array_value = $array->[1];
    shift $array_value;
    # if could not dethory data, should make an copy of array
    return ['array', $array_value];
  }
  error("could not shift $array_type");
}

# get Spp value type
sub eval_type {
  my $atom = shift;
  return ['str', type(eval_atom($atom))];
}

sub eval_is {
  my $args = shift;
  my $atoms = eval_atoms($args);
  my ($sym, $type) = @{ $atoms };
  my $type_str = type($type);
  if ($type_str eq 'str') {
    if (type($sym) eq $type->[1]) {
      return $TRUE;
    }
    return $FALSE;
  }
  error("could not compare $type_str, only accept str");
}

sub eval_assign {
  my $atoms = shift;
  my $head_atom = $atoms->[0];
  if ($head_atom->[0] eq 'sym') {
    my $sym = $head_atom;
    my $value = eval_atom($atoms->[1]);
    return eval_sym_assign($sym, $value);
  }
  # (x y z) = [1 2 3]
  if ($head_atom->[0] eq 'list') {
    my $syms = $head_atom->[1];
    my $array = eval_atom($atoms->[1]);
    if (all_is_spp_sym($syms) and $array->[0] eq 'array') {
      my $values = $array->[1];
      return eval_syms_assign($syms, $values);
    }
  }
  error("assign syntax error: $atoms");
}

sub eval_while {
  my $atoms = shift;
  if (len($atoms) < 2) { error('(while ...) args less 2') }
  my $guide_expr = $atoms->[0];
  my $while_exprs = rest($atoms);
  my $return_value = $TRUE;
  while (is_true(eval_bool($guide_expr))) {
    my $context = uuid();
    in_block($context);
    $return_value = eval_exprs($while_exprs);
    if ($ST->{$CALL}{':return'} == 1) {
      out_block($context);
      return $return_value;
    }
    if ($ST->{$CONTEXT}{':break'} == 1) {
      out_block($context);
      last;
    }
    out_block($context);
  }
  return $return_value;
}

sub eval_push {
  my $args = shift;
  my $eval_atoms = eval_atoms($args);
  my ($array, $element) = @{ $eval_atoms };
  if ($array->[0] eq 'array') {
    my $array_value = $array->[1];
    push $array_value, $element;
    return ['array', $array_value];
  }
}

sub eval_unshift {
  my $atoms = shift;
  my $eval_atoms = eval_atoms($atoms);
  my ($element, $array) = @{ $eval_atoms };
  if ($array->[0] eq 'array') {
    my $array_value = $array->[1];
    unshift $array_value, $element;
    return ['array', $array_value];
  }
}

sub eval_in {
  my $args = shift;
  my $atoms = eval_atoms($args);
  my ($element, $array) = @{ $atoms };
  if ($array->[0] eq 'array') {
    return $TRUE if in($element, $array->[1]);
    return $FALSE;
  }
  error("Only implement element in <array>");
}

sub boot_spp {
  my $rule_file = get_rule_file('Spp');
  my $spp_rule = load_file($rule_file);
  my $boot_rule = eval_atom($spp_rule);
  return $TRUE if is_same($boot_rule, ['context', $RULE]);
  error("Could not Boot Spp rule");
}

sub spp {
  my $spp_file = shift;
  my $spp_str = trim(read_file($spp_file));
  boot_spp();
  my $match = match_rule($RULE, $spp_str);
  if (is_match($match)) {
    my $opt_ast = opt_atom($match);
    return atom_to_str(eval_atom($opt_ast));
  }
  my $sub_spp_str = substr($spp_str, 0, 20);
  error("Could not parse:\n $sub_spp_str ... ");
}

sub repl {
  boot_spp();
  say "This is Spp REPL(Perl5), type 'exit' to exit.";
  while (1) {
    print '>>> ';
    my $line = <STDIN>;
    my $str = trim($line);
    exit() if $str eq 'exit';
    my $match = match_rule($RULE, $str);
    if (is_match($match)) {
      my $opt_ast = opt_atom($match);
      # see $opt_ast;
      my $eval_value = eval_atom($opt_ast);
      # see $eval_value;
      say atom_to_str($eval_value);
    } else {
      say "Could not parse str: $str"
    }
  }
}

=head1 AUTHOR

Michael Song, C<< <10435916 at qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-spp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spp>

=item * Search CPAN

L<http://search.cpan.org/dist/Spp/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Michael Song.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Spp
