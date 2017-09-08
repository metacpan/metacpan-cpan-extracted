package Spp::Match;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(match_rule);

use Spp::Builtin;
use Spp::Cursor;
use Spp::IsChar;
use Spp::IsAtom;

sub match_rule {
   my ($rule, $cursor) = @_;
   my ($name, $value)  = @{$rule};
   given ($name) {
      when ('Rules') { match_rules($value, $cursor) }
      when ('Group') { match_rules($value, $cursor) }
      when ('Branch') { match_branch($value, $cursor) }
      when ('Lbranch'){ match_lbranch($value, $cursor) }
      when ('Rept') { match_rept($value, $cursor) }
      when ('Look') { match_look($value, $cursor) }
      when ('Cclass') { match_cclass($value, $cursor) }
      when ('Chclass') { match_chclass($value, $cursor) }
      when ('Nchclass') { match_nchclass($value, $cursor) }
      when ('Str') { match_str($value, $cursor) }
      when ('Char') { match_char($value, $cursor) }
      when ('Assert') { match_assert($value, $cursor) }
      when ('Not') { match_not($value, $cursor) }
      when ('Till') { match_till($value, $cursor) }
      when ('Rtoken') { match_rtoken($value, $cursor) }
      when ('Ctoken') { match_ctoken($value, $cursor) }
      when ('Ntoken') { match_ntoken($value, $cursor) }
      when ('Any') { match_any($value, $cursor) }
      when ('Expr') { match_expr($value, $cursor) }
      when ('Sym') { match_sym($value, $cursor) }
      default { die "unknown rule type $name to match!" }
   }
}

sub match_any {
   my ($any, $cursor) = @_;
   my $char = get_char($cursor);
   if ($char eq chr(0)) { return ['false'] }
   go($cursor);
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
         return ['true'] if get_char($cursor) eq chr(0);
         return ['false'];
      }
      when ('^^') {
         return ['true'] if pre_char($cursor) eq "\n";
         return ['true'] if $cursor->{off} == 0;
         return ['false'];
      }
      when ('$$') {
         return ['true'] if get_char($cursor) eq "\n";
         return ['true'] if get_char($cursor) eq chr(0);
         return ['false'];
      }
      default { die "error assert char: <$assert>!" }
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
   my $cache = cache($cursor);
   for my $rule (@{$branch}) {
      my $match = match_rule($rule, $cursor);
      if (is_match($match)) { return $match }
      recover($cursor, $cache);
   }
   return ['false'];
}

sub match_lbranch {
   my ($branch, $cursor) = @_;
   my $cache     = cache($cursor);
   my $max_match = ['false'];
   my $max_cache = $cache;
   for my $rule (@{$branch}) {
      my $match = match_rule($rule, $cursor);
      if (is_match($match)) {
         if ($cursor->{off} >= $max_cache->[1]) {
            $max_cache = cache($cursor);
            $max_match = $match;
         }
      }
      recover($cursor, $cache);
   }
   recover($cursor, $max_cache);
   return $max_match;
}

sub match_ntoken {
   my ($name, $cursor) = @_;
   my $rule  = $cursor->{ns}->{$name};
   my $cache = cache($cursor);
   my $match = match_rule($rule, $cursor);
   return $match if is_bool($match);
   my $from  = $cache->[1];
   my $len   = $cursor->{off} - $from;
   my $str   = substr($cursor->{str}, $from, $len);
   my $cname = '$' . $name;
   $cursor->{ns}->{$cname} = ['Str', $str];
   if ($cursor->{'mode'} != 0) {
      push @{$cache}, $len;
      return name_match_pos($name, $match, $cache);
   }
   return name_match($name, $match);
}

sub match_ctoken {
   my ($name, $cursor) = @_;
   my $rule  = $cursor->{'ns'}{$name};
   my $from  = $cursor->{'off'};
   my $match = match_rule($rule, $cursor);
   return $match if is_bool($match);
   my $len   = $cursor->{'off'} - $from;
   my $str   = substr($cursor->{'str'}, $from, $len);
   my $cname = '$' . $name;
   $cursor->{'ns'}{$cname} = ['Str', $str];
   return $match;
}

sub match_rtoken {
   my ($name, $cursor) = @_;
   my $rule = $cursor->{ns}{$name};
   my $match = match_rule($rule, $cursor);
   return ['false'] if is_false($match);
   return ['true'];
}

sub match_not {
   my ($rule, $cursor) = @_;
   my $cache = cache($cursor);
   my $match = match_rule($rule, $cursor);
   if (is_false($match)) {
      recover($cursor, $cache);
      return ['true'];
   }
   return ['false'];
}

sub match_till {
   my ($rule, $cursor) = @_;
   my @buf = ();
   while ($cursor->{off} < $cursor->{len}) {
      my $char = get_char($cursor);
      my $match = match_rule($rule, $cursor);
      if (is_match($match)) {
         my $gather_str - join '', @buf;
         return gather_match($gather_str, $match);
      }
      push @buf, $char;
      go($cursor);
   }
   return ['false'];
}

sub match_rept {
   my ($rule, $cursor) = @_;
   my $gather = ['true'];
   my $time   = 0;
   my ($rept, $atom) = @{$rule};
   my ($min,  $max)  = get_rept_time($rept);
   while ($time != $max) {
      my $cache = cache($cursor);
      my $match = match_rule($atom, $cursor);
      if (is_false($match)) {
         return ['false'] if $time < $min;
         recover($cursor, $cache);
         return $gather;
      }
      $time++;
      $gather = gather_match($gather, $match);
   }
   return $gather;
}

sub get_rept_time {
   my $rept = shift;
   given ($rept) {
      when ('?')  { return (0,  1) }  
      when ('*')  { return (0, -1) } 
      when ('+')  { return (1, -1) } 
      when ('*?') { return (0, -1) }
      when ('+?') { return (1, -1) }
      default { die "error rept str: <$rept>!" }
   }
}

sub match_look {
   my ($rule, $cursor) = @_;
   my ($rept, $atom, $look) = @{$rule};
   my ($min, $max) = get_rept_time($rept);
   my ($gather, $time)   = (['true'], 0);
   while ($time != $max) {
      my $cache = cache($cursor);
      my $match = match_rule($atom, $cursor);
      if (is_false($match)) {
         return ['false'] if $time > $min;
         recover($cursor, $cache);
         $match = match_rule($look, $cursor);
         return ['false'] if is_false($match);
         return gather_match($gather, $match);
      }
      $time++;
      $gather = gather_match($gather, $match);
      if ($time >= $min) {
         $cache = cache($cursor);
         $match = match_rule($look, $cursor);
         if (is_match($match)) {
            return gather_match($gather, $match)
         }
         recover($cursor, $cache);
      }
   }
   return ['false'];
}

sub match_str {
   my ($str, $cursor) = @_;
   for my $char (split('', $str)) {
      if ($char ne get_char($cursor)) { return ['false'] }
      go($cursor);
   }
   return $str;
}

sub match_char {
   my ($char, $cursor) = @_;
   return ['false'] if $char ne get_char($cursor);
   go($cursor);
   return $char;
}

sub match_chclass {
   my ($atoms, $cursor) = @_;
   my $char = get_char($cursor);
   for my $atom (@{$atoms}) {
      if (match_catom($atom, $char)) {
         go($cursor);
         return $char;
      }
   }
   return ['false'];
}

sub match_nchclass {
   my ($atoms, $cursor) = @_;
   my $char = get_char($cursor);
   return ['false'] if $char eq chr(0);
   for my $atom (@{$atoms}) {
      return ['false'] if match_catom($atom, $char);
   }
   go($cursor);
   return $char;
}

sub match_catom {
   my ($atom, $char)  = @_;
   my ($name, $value) = @{$atom};
   given ($name) {
      when ("Range") { match_range($value, $char) }
      when ("Cclass") { is_match_cclass($value, $char) }
      when ("Char") { return $value eq $char }
      default { die("unknown chclass node: <$name>!") }
   }
}

sub match_cclass {
   my ($cclass, $cursor) = @_;
   my $char = get_char($cursor);
   return ['false'] if $char eq chr(0);
   if (is_match_cclass($cclass, $char)) {
      go($cursor);
      return $char;
   }
   return ['false'];
}

sub is_match_cclass {
   my ($cchar, $char) = @_;
   given ($cchar) {
      when ('a') { return is_char_alpha($char) }
      when ('A') { return !is_char_alpha($char) }
      when ('d') { return is_char_digit($char) }
      when ('D') { return !is_char_digit($char) }
      when ('h') { return is_char_hspace($char) }
      when ('H') { return !is_char_hspace($char) }
      when ('l') { return is_char_lower($char) }
      when ('L') { return !is_char_lower($char) }
      when ('s') { return is_char_space($char) }
      when ('S') { return !is_char_space($char) }
      when ('u') { return is_char_upper($char) }
      when ('U') { return !is_char_upper($char) }
      when ('v') { return is_char_vspace($char) }
      when ('V') { return !is_char_vspace($char) }
      when ('w') { return is_char_words($char) }
      when ('W') { return !is_char_words($char) }
      when ('x') { return is_char_xdigit($char) }
      when ('X') { return !is_char_xdigit($char) }
      default    { die "unknown cclass $cchar" }
   }
}

sub match_range {
   my ($range, $char) = @_;
   my ($from,  $to) = @{$range};
   return ($from le $char && $char le $to);
}

sub match_expr {
   my ($expr, $cursor) = @_;
   my $atom = eval_expr($expr, $cursor->{ns});
   return match_atom($atom, $cursor);
}

sub match_sym {
   my ($name, $cursor) = @_;
   my $value = eval_sym($name, $cursor->{ns});
   my $match = match_atom($value, $cursor);
   if (is_false($match)) { return $match }
   my $token_name = rest($name);
   my $char = first($token_name);
   if (is_char_upper($char)) { return [$token_name, $match] }
   if ($char eq '_') { return ['true'] }
   return $match;
}

sub match_atom {
   my ($atom, $cursor) = @_;
   return $atom if is_bool($atom);
   my ($name, $value) = @{$atom};
   given ($name) {
      when ('Array') { return match_array($value, $cursor) }
      when ('Str') { return match_str($value, $cursor) }
      default { die "not implement atom $name" }
   }
}

sub match_array {
   my ($array, $cursor) = @_;
   return ['false'] if len($array) == 0;
   return match_lbranch($array, $cursor);
}

sub name_match_pos {
   my ($name, $match, $pos) = @_;
   if (is_true($match)) { return $match }
   if (is_atom($match)) { return [$name, [$match], $pos] }
   return [$name, $match, $pos];
}

sub name_match {
   my ($name, $match) = @_;
   if (is_true($match)) { return $match }
   if (is_atom($match)) { return [$name, [$match]] }
   return [$name, $match];
}

sub gather_match {
   my ($gather, $match) = @_;
   return $gather if is_true($match);
   return $match  if is_true($gather);
   if (is_str($match)) {
      return $gather . $match if is_str($gather);
      return $gather;
   }
   if (is_str($gather)) { return $match }
   if (is_atom($gather)) {
      return [$gather, $match] if is_atom($match);
      return [$gather, @{$match}];
   }
   return [@{$gather}, $match] if is_atom($match);
   return [@{$gather}, @{$match}];
}

sub eval_atom {
   my ($atom, $ns) = @_;
   my ($name, $value) = @{$atom};
   given ($name) {
      when ('Str')   { return $atom }
      when ('Sym')   { return eval_sym($value, $ns) }
      when ('Expr')  { return eval_expr($value, $ns) }
      when ('Array') { return eval_array($value, $ns) }
      default { die "Could not eval atom: <$name>!"; }
   }
}

sub eval_sym {
   my ($name, $ns) = @_;
   if (exists $ns->{$name}) { return $ns->{$name} }
   die "variable not define: <$name>.";
}

sub eval_expr {
   my ($expr, $ns) = @_;
   my $name = shift @{$expr};
   given ($name) {
      when ('push') { eval_push($expr, $ns) }
      when ('my') { eval_my($expr, $ns) }
      when ('say') { eval_say($expr, $ns) }
      default { die "not implement action: <$name>."; }
   }
}

sub eval_array {
   my ($array, $ns) = @_;
   if (len($array) == 0) {
      return ['Array', $array]
   }
   my $atoms = eval_atoms($array, $ns);
   return ['Array', $atoms];
}

sub eval_push {
   my ($atoms, $ns) = @_;
   my $sym = $atoms->[0];
   if (is_atom_sym($sym)) {
      my $eval_atoms = eval_atoms($atoms, $ns);
      my ($array, $element) = @{$eval_atoms};
      push @{ $array->[1] }, $element;
      my $name = $sym->[1];
      $ns->{$name} = $array;
      return ['true'];
   }
   die 'push only accept array symbol!';
}

sub eval_my {
   my ($atoms, $ns) = @_;
   my $sym = $atoms->[0];
   my $value = eval_atom($atoms->[1], $ns);
   if (is_atom_sym($sym)) {
      my $name = $sym->[1];
      $ns->{$name} = $value;
      return ['true'];
   }
   die 'only assign symbol!';
}

sub eval_say {
   my ($atoms, $ns) = @_;
   my $eval_atoms = eval_atoms($atoms, $ns);
   my $str = $eval_atoms->[0];
   if (is_atom_str($str)) {
      say $str->[1];
      return ['true'];
   }
   my $type = $str->[0];
   die "say only accept Str: <$type>";
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
