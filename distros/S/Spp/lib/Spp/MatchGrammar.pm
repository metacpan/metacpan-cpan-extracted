# Copyright 2016 The Michael Song. All rights rberved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

package Spp::MatchGrammar;

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(match_grammar error_report);

use 5.012;
no warnings "experimental";
use List::Util qw(all);
use Spp::Tools;
use Spp::Cursor;
use Spp::IsChar;
use Spp::IsAtom;
use Spp::ToSpp qw(to_spp);

sub match_grammar {
  my ($door, $cursor) = @_;
  my $door_rule = $cursor->{ns}{$door};
  my $match = match_rule($door_rule, $cursor);
  return ['false'] if is_false($match);
  return ['true'] if is_true($match);
  my $char = first($door);
  return [$door, $match] if is_upper($char);
  return $match if is_lower($char);
  return ['true'] if $char eq '_';
}

sub _match_rule {
   my ($rule, $cursor) = @_;
   my ($name, $value)  = @{$rule};
   given ($name) {
      when ('Rules') { match_rules($value, $cursor) }
      when ('Group') { match_rules($value, $cursor) }
      when ('Branch') { match_branch($value, $cursor) }
      when ('Lbranch') { match_lbranch($value, $cursor) }
      when ('Rept') { return match_rept($value, $cursor) }
      when ('Look') { return match_look($value, $cursor) }
      when ('Cclass') { return match_cclass($value, $cursor) }
      when ('Chclass') { return match_chclass($value, $cursor) }
      when ('Nchclass') { return match_nchclass($value, $cursor) }
      when ('Str') { return match_str($value, $cursor) }
      when ('Char') { return match_char($value, $cursor) }
      when ('Assert') { return match_assert($value, $cursor) }
      when ('Not') { return match_not($value, $cursor) }
      when ('Till') { return match_till($value, $cursor) }
      when ('Rtoken') { return match_rtoken($value, $cursor) }
      when ('Ctoken') { return match_ctoken($value, $cursor) }
      when ('Ntoken') { return match_ntoken($value, $cursor) }
      when ('Any') { return match_any($value, $cursor) }
      when ('Expr') { return match_expr($value, $cursor) }
      when ('Sym') { return match_sym($value, $cursor) }
      default { error("unknown rule type $name to match") }
   }
}

sub match_any {
   my ($any, $cursor) = @_;
   my $char = getchar($cursor);
   return ['false'] if $char eq chr(0);
   $cursor->{off}++;
   return $char;
}

sub match_assert {
   my ($assert, $cursor) = @_;
   given ($assert) {
      when ('^') {
         return ['true'] if $cursor->{off} == 0;
         return ['false'];
      }
      when ('$') {
         return ['true'] if getchar($cursor) eq chr(0);
         return ['false'];
      }
      when ('^^') {
         return ['true'] if prechar($cursor) eq "\n";
         return ['true'] if $cursor->{off} == 0;
         return ['false'];
      }
      when ('$$') {
         return ['true'] if nextchar($cursor) eq "\n";
         return ['true'] if nextchar($cursor) eq chr(0);
         return ['false'];
      }
      default { error("error assert char: |$assert|") }
   }
}

sub match_rules {
   my ($rules, $cursor) = @_;
   my $gather = ['true'];
   for my $rule (@{$rules}) {
      my $match = match_rule($rule, $cursor);
      return ['false'] if is_false($match);
      $gather = gather_match($gather, $match);
   }
   return $gather;
}

sub match_branch {
   my ($branch, $cursor) = @_;
   my $cache = $cursor->{off};
   for my $rule (@{$branch}) {
      my $match = match_rule($rule, $cursor);
      if (is_false($match)) {
         $cursor->{off} = $cache;
      } else { return $match }
   }
   return ['false'];
}

sub match_lbranch {
   my ($branch, $cursor) = @_;
   my $cache      = $cursor->{off};
   my $max_match  = ['false'];
   my $max_length = $cache;
   for my $rule (@{$branch}) {
      my $match = match_rule($rule, $cursor);
      if (!is_false($match)) {
         if ($cursor->{off} >= $max_length) {
            $max_length = $cursor->{off};
            $max_match  = $match;
         }
      }
      $cursor->{off} = $cache;
   }
   $cursor->{off} = $max_length;
   return $max_match;
}

sub match_ntoken {
   my ($name, $cursor) = @_;
   my $rule  = $cursor->{ns}->{$name};
   my $cache = $cursor->{off};
   my $match = match_rule($rule, $cursor);
   return $match if is_bool($match);
   my $len    = $cursor->{off} - $cache;
   my $str    = substr($cursor->{str}, $cache, $len);
   my $c_name = '$' . $name;
   $cursor->{ns}->{$c_name} = [ 'Str', $str ];
   return name_match($name, $match);
}

sub match_ctoken {
   my ($name, $cursor) = @_;
   my $rule = $cursor->{ns}->{$name};
   my $cache = $cursor->{off};
   my $match = match_rule($rule, $cursor);
   return $match if is_bool($match);
   my $len    = $cursor->{off} - $cache;
   my $str    = substr($cursor->{str}, $cache, $len);
   my $c_name = '$' . $name;
   $cursor->{ns}->{$c_name} = [ 'Str', $str ];
   return $match;
}

sub match_rtoken {
   my ($name, $cursor) = @_;
   my $rule = $cursor->{ns}->{$name};
   my $match = match_rule($rule, $cursor);
   return ['false'] if is_false($match);
   return ['true'];
}

sub match_not {
   my ($rule, $cursor) = @_;
   my $cache = $cursor->{off};
   my $match = match_rule($rule, $cursor);
   if (is_false($match)) {
      $cursor->{off} = $cache;
      return ['true'];
   }
   return ['false'];
}

sub match_till {
   my ($rule, $cursor) = @_;
   my @buf = ();
   my $match = match_rule($rule, $cursor);
   if (is_false($match)) {
      my $char = getchar($cursor);
      push @buf, $char;
      $cursor->{off}++;
   }
   else { return $match }
   while (getchar($cursor) ne chr(0)) {
      $match = match_rule($rule, $cursor);
      my $char = getchar($cursor);
      push @buf, $char;
      if (is_false($match)) {
         $cursor->{off}++;
      }
      else {
         return gather_match(join('', @buf), $match);
      }
   }
   return ['false'];
}

sub match_rept {
   my ($rule,   $cursor) = @_;
   my ($gather, $time)   = (['true'], 0);
   my ($rept,   $atom)   = @{$rule};
   my ($min,    $max)    = get_rept_time($rept);
   while ($time != $max) {
      my $cache = $cursor->{off};
      my $match = match_rule($atom, $cursor);
      if (is_false($match)) {
         return ['false'] if $time < $min;
         $cursor->{off} = $cache;
         return $gather;
      }
      $time++;
      $gather = gather_match($gather, $match);
   }
   return $gather;
}

sub get_rept_time {
   my $rept = shift;
   return (0, 1)  if $rept eq '?';
   return (0, -1) if $rept eq '*';
   return (1, -1) if $rept eq '+';
   return (0, -1) if $rept eq '*?';
   return (1, -1) if $rept eq '+?';
}

sub match_look {
   my ($rule,   $cursor) = @_;
   my ($rept,   @atoms)  = @{$rule};
   my ($min,    $max)    = get_rept_time($rept);
   my ($atom,   $look)   = @atoms;
   my ($gather, $time)   = (['true'], 0);
   while ($time != $max) {
      my $cache = $cursor->{off};
      my $match = match_rule($atom, $cursor);
      if (is_false($match)) {
         return ['false'] if $time > $min;
         $cursor->{off} = $cache;
         $match = match_rule($look, $cursor);
         return ['false'] if is_false($match);
         return gather_match($gather, $match);
      }
      $time++;
      $gather = gather_match($gather, $match);
      if ($time >= $min) {
         $cache = $cursor->{off};
         $match = match_rule($look, $cursor);
         if (is_false($match)) { $cursor->{off} = $cache }
         else { return gather_match($gather, $match) }
      }
   }
   return ['false'];
}

sub match_str {
   my ($str, $cursor) = @_;
   for my $char (split('', $str)) {
      return ['false'] if $char ne getchar($cursor);
      $cursor->{off}++;
   }
   return $str;
}

sub match_char {
   my ($char, $cursor) = @_;
   return ['false'] if $char ne getchar($cursor);
   $cursor->{off}++;
   return $char;
}

sub match_chclass {
   my ($atoms, $cursor) = @_;
   my $char = getchar($cursor);
   for my $atom (@{$atoms}) {
      if (match_catom($atom, $char)) {
         $cursor->{off}++;
         return $char;
      }
   }
   return ['false'];
}

sub match_nchclass {
   my ($atoms, $cursor) = @_;
   my $char = getchar($cursor);
   return ['false'] if $char eq chr(0);
   for my $atom (@{$atoms}) {
      return ['false'] if match_catom($atom, $char);
   }
   $cursor->{off}++;
   return $char;
}

sub match_catom {
   my ($atom, $char)  = @_;
   my ($name, $value) = @{$atom};
   given ($name) {
      when ("Range") { return match_range($value, $char) }
      when ("Cclass") { return is_match_cclass($value, $char) }
      when ("Char")   { return $value eq $char }
      default { error("unknown chclass node: <$name>") }
   }
}

sub match_cclass {
   my ($x, $cursor) = @_;
   my $char = getchar($cursor);
   return ['false'] if $char eq chr(0);
   if (is_match_cclass($x, $char)) {
      $cursor->{off}++;
      return $char;
   }
   return ['false'];
}

sub is_match_cclass {
   my ($class_char, $char) = @_;
   given ($class_char) {
      when ('a') { return is_alpha($char) }
      when ('A') { return !is_alpha($char) }
      when ('d') { return is_digit($char) }
      when ('D') { return !is_digit($char) }
      when ('h') { return is_hspace($char) }
      when ('H') { return !is_hspace($char) }
      when ('l') { return is_lower($char) }
      when ('L') { return !is_lower($char) }
      when ('s') { return is_space($char) }
      when ('S') { return !is_space($char) }
      when ('u') { return is_upper($char) }
      when ('U') { return !is_upper($char) }
      when ('v') { return is_vspace($char) }
      when ('V') { return !is_vspace($char) }
      when ('w') { return is_words($char) }
      when ('W') { return !is_words($char) }
      when ('x') { return is_xdigit($char) }
      when ('X') { return !is_xdigit($char) }
      default    { error("unknown cclass $class_char") }
   }
}

sub match_range {
   my ($range,     $char)    = @_;
   my ($from_char, $to_char) = @{$range};
   return $from_char le $char and $char le $to_char;
}

sub match_expr {
   my ($expr, $cursor) = @_;
   my $atom = eval_expr($expr, $cursor->{ns});
   return match_atom($atom, $cursor);
}

sub match_sym {
   my ($name, $cursor) = @_;
   my $value = eval_sym($name, $cursor->{ns});
   return match_atom($value, $cursor);
}

sub match_atom {
   my ($atom, $cursor) = @_;
   return $atom if is_bool($atom);
   my ($name, $value) = @{$atom};
   given ($name) {
      when ('Array') { return match_array($value, $cursor) }
      when ('Str') { return match_str($value, $cursor) }
      default { error("not implement atom $name") }
   }
}

sub match_array {
   my ($array, $cursor) = @_;
   return ['false'] if len($array) == 0;
   if (all { is_str_atom($_) } @{$array}) {
      return match_lbranch($array, $cursor);
   } else {
      say to_json($array);
      error("match array include not Str Atom");
   }
}

sub name_match {
   my ($name, $match) = @_;
   return $match if is_true($match);
   return [ $name, [$match] ] if is_atom($match);
   return [ $name, $match ];
}

sub gather_match {
   my ($gather, $match) = @_;
   return $gather if is_true($match);
   return $match  if is_true($gather);
   if (is_chars($match)) {
      return $gather . $match if is_chars($gather);
      return $gather;
   }
   if (is_chars($gather)) { return $match }
   if (is_atom($gather)) {
      return [ $gather, $match ] if is_atom($match);
      return [ $gather, @{$match} ];
   }
   return [ @{$gather}, $match ] if is_atom($match);
   return [ @{$gather}, @{$match} ];
}

sub match_rule {
   my ($x_rule, $cursor) = @_;
   if ($cursor->{debug} == 1) {
      my $off      = $cursor->{off};
      my $rule     = to_spp($x_rule);
      my $flag     = '->';
      my $pass_str = substr($cursor->{str}, $off, 10);
      my $str      = to_trace_str($pass_str, 10);
      my $indent   = ' ' x $cursor->{depth};
      printf("%d|%s|%s %s %s\n", $off, $str, $indent, $flag, $rule);
      $cursor->{depth}++;
      my $match = _match_rule($x_rule, $cursor);
      $cursor->{depth}--;
      if   (is_false($match)) { $flag = '<-' }
      else                      { $flag = 'ok' }
      $off      = $cursor->{off};
      $pass_str = substr($cursor->{str}, $off, 10);
      $str      = to_trace_str($pass_str, 10);
      printf("%d|%s|%s %s %s\n", $off, $str, $indent, $flag, $rule);
      return $match;
   }
   else {
      if ($cursor->{maxoff} < $cursor->{off}) {
         $cursor->{maxoff} = $cursor->{off};
      }
      return _match_rule($x_rule, $cursor);
   }
}

sub error_report {
   my $cursor   = shift;
   my $off      = $cursor->{maxoff};
   my $pass_str = substr($cursor->{str}, $off, 10);
   my $line     = count($pass_str, "\n") + 1;
   my $str      = to_trace_str($pass_str, 20);
   printf("block at: line: %d |^%s\n", $line, $str);
   exit();
}

sub eval_atom {
   my ($atom, $ns) = @_;
   if (!is_atom($atom)) {
      say to_json($atom);
      error("not atom to eval $atom")
   }
   my ($name, $value) = @{$atom};
   given ($name) {
      when ('Str') { return $atom }
      when ('Sym') { return eval_sym($value, $ns) }
      when ('Expr') { return eval_expr($value, $ns) }
      when ('Array') { return eval_array($value, $ns) }
      when ('String') { return eval_string($value, $ns) }
      default {
         # say to_json($atom); 
         error("Not implement eval atom $name");
      }
   }
}

sub eval_sym {
   my ($name, $ns) = @_;
   if (exists $ns->{$name}) {
      return $ns->{$name};
   } else {
      error("variable not define: $name");
   }
}

sub eval_expr {
   my ($expr, $ns)   = @_;
   my ($name, @args) = @{$expr};
   given ($name) {
      when ("push") { return eval_push([@args], $ns) }
      when ("def") { return eval_def([@args], $ns) }
      when ("say") { return eval_say([@args], $ns) }
      default { warn("not implement action: $name") }
   }
}

sub eval_array {
   my ($array, $ns) = @_;
   if (len($array) == 0) { return [ "Array", $array ] }
   my $atoms = eval_atoms($array, $ns);
   return [ "Array", $atoms ];
}

sub eval_string {
   my ($atoms, $ns) = @_;
   $atoms = eval_atoms($atoms, $ns);
   my @strs = ();
   for my $atom (@{$atoms}) {
      if (is_str_atom($atom)) {
         push @strs, $atom->[1];
      } else {
         error("String only accept Str atom");
      }
   }
   my $str = join('', @strs);
   return [ "Str", $str ];
}

sub eval_push {
   my ($atoms, $ns) = @_;
   my $sym = $atoms->[0];
   if (!is_sym($sym)) {
     error("push only accept symbol");
   }
   my $name = $sym->[1];
   $atoms = eval_atoms($atoms, $ns);
   my ($array, $element) = @{$atoms};
   $array = ['Array', [@{$array->[1]}, $element]];
   $ns->{$name} = $array;
   return ['true'];
}

# return should is error nil or some error tips
sub eval_def {
   my ($atoms, $ns) = @_;
   my $sym = $atoms->[0];
   my $value = eval_atom($atoms->[1], $ns);
   if (!is_sym($sym)) { error("only assign symbol") }
   my $name = $sym->[1];
   $ns->{$name} = $value;
   return ['true'];
}

sub eval_say {
   my ($atoms, $ns) = @_;
   $atoms = eval_atoms($atoms, $ns);
   my $str = first($atoms);
   if (!is_str_atom($str)) {
      error("say only accept Str: {$str->[0]}");
   }
   say(tail($str));
   return ['true'];
}

sub eval_atoms {
   my ($atoms, $ns) = @_;
   my $eval_atoms = [];
   for my $atom (@{$atoms}) {
      my $eval_atom = eval_atom($atom, $ns);
      push @{$eval_atoms}, $eval_atom;
   }
   return $eval_atoms;
}
   
1;
