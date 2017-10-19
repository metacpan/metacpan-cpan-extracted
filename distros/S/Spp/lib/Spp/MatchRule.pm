package Spp::MatchRule;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(match_spp_rule match_spp_any match_spp_assert match_spp_rules match_spp_branch match_spp_ntoken match_spp_ctoken match_spp_rtoken match_spp_not match_spp_till match_spp_rept match_spp_look match_spp_str match_spp_char match_spp_chclass match_spp_nclass match_spp_catom match_spp_cclass is_match_spp_cclass match_spp_range match_spp_sym get_spp_sym_value match_spp_value match_spp_call get_spp_call_value eval_spp_my eval_spp_push get_spp_atom_value get_spp_array_value get_spp_atoms_value name_spp_match gather_spp_match);

use Spp::Builtin;
use Spp::Tools;
use Spp::Cursor;
use Spp::ToSpp;

sub _match_spp_rule {
  my ($c, $rule) = @_;
  if (1) {
    my $off    = $c->{'off'};
    my $char   = get_char($c);
    my $indent = ' ' x $c->{'depth'};
    my $spp    = to_spp($rule);
    say "$off| $char |$indent -> $spp";
    $c->{'depth'}++;
    my $match = _match_spp_rule($c, $rule);
    $c->{'depth'}--;
    $off    = $c->{'off'};
    $char   = get_char($c);
    $indent = ' ' x $c->{'depth'};
    my $flag = 'ok';
    if (is_false($match)) { $flag = "<-" }
    say "$off| $char |$indent $flag $spp";
    return $match;
  }
  else { return _match_spp_rule($c, $rule) }
}

sub match_spp_rule {
  my ($c,    $rule)  = @_;
  my ($name, $value) = flat($rule);
  given ($name) {
    when ('Rules') { return match_spp_rules($c, $value) }
    when ('Group') { return match_spp_rules($c, $value) }
    when ('Branch') { return match_spp_branch($c, $value) }
    when ('Rept') { return match_spp_rept($c, $value) }
    when ('Look') { return match_spp_look($c, $value) }
    when ('Cclass') { return match_spp_cclass($c, $value) }
    when ('Chclass') {
      return match_spp_chclass($c, $value)
    }
    when ('Nclass') { return match_spp_nclass($c, $value) }
    when ('Str') { return match_spp_str($c, $value) }
    when ('Char') { return match_spp_char($c, $value) }
    when ('Assert') { return match_spp_assert($c, $value) }
    when ('Not') { return match_spp_not($c, $value) }
    when ('Till') { return match_spp_till($c, $value) }
    when ('Rtoken') { return match_spp_rtoken($c, $value) }
    when ('Ctoken') { return match_spp_ctoken($c, $value) }
    when ('Ntoken') { return match_spp_ntoken($c, $value) }
    when ('Any') { return match_spp_any($c, $value) }
    when ('Call') { return match_spp_call($c, $value) }
    when ('Sym') { return match_spp_sym($c, $value) }
    default { say "unknown rule: $name to match!" }
  }
}

sub match_spp_any {
  my ($c, $any) = @_;
  my $char = get_char($c);
  if ($char eq End) { return False }
  to_next($c);
  return $char;
}

sub match_spp_assert {
  my ($c, $assert) = @_;
  given ($assert) {
    when ('$') {
      if (get_char($c) eq End) { return True }
      return False
    }
    when ('^') {
      if (pre_char($c) eq "\n") { return True }
      if ($c->{'off'} == 0)     { return True }
      return False
    }
    when ('$$') {
      if (get_char($c) eq "\n") { return True }
      if (get_char($c) eq End)  { return True }
      return False
    }
    default { say "unknown assert: $assert" }
  }
}

sub match_spp_rules {
  my ($c, $rules) = @_;
  my $gather = True;
  for my $rule (@{ atoms($rules) }) {
    my $match = match_spp_rule($c, $rule);
    if (is_false($match)) { return False }
    $gather = gather_spp_match($gather, $match);
  }
  return $gather;
}

sub match_spp_branch {
  my ($c, $branch) = @_;
  my $cache = cache($c);
  for my $rule (@{ atoms($branch) }) {
    my $match = match_spp_rule($c, $rule);
    if (not(is_false($match))) { return $match }
    reset_cache($c, $cache);
  }
  return False;
}

sub match_spp_ntoken {
  my ($c, $name) = @_;
  my $table = $c->{'ns'};
  my $rule  = $table->{$name};
  my $cache = cache($c);
  my $match = match_spp_rule($c, $rule);
  if (is_bool($match)) { return $match }
  if (is_str($match)) {
    my $ref_name = add('@', $name);
    my $ns = $c->{'ns'};
    $ns->{$ref_name} = $match;
  }
  return name_spp_match($name, $match, $cache);
}

sub match_spp_ctoken {
  my ($c, $name) = @_;
  my $table = $c->{'ns'};
  my $rule  = $table->{$name};
  my $match = match_spp_rule($c, $rule);
  if (is_str($match)) {
    my $ref_name = add('@', $name);
    my $ns = $c->{'ns'};
    $ns->{$ref_name} = $match;
  }
  return $match;
}

sub match_spp_rtoken {
  my ($c, $name) = @_;
  my $table = $c->{'ns'};
  my $rule  = $table->{$name};
  my $match = match_spp_rule($c, $rule);
  if (is_false($match)) { return False }
  return True;
}

sub match_spp_not {
  my ($c, $rule) = @_;
  my $cache = cache($c);
  my $match = match_spp_rule($c, $rule);
  if (is_false($match)) {
    reset_cache($c, $cache);
    return True;
  }
  return False;
}

sub match_spp_till {
  my ($c, $rule) = @_;
  my $buf = [];
  while ($c->{'off'} < $c->{'len'}) {
    my $char  = get_char($c);
    my $cache = cache($c);
    my $match = match_spp_rule($c, $rule);
    if (not(is_false($match))) {
      my $gather_str = join '', @{$buf};
      return gather_spp_match($gather_str, $match);
    }
    push @{$buf}, $char;
    reset_cache($c, $cache);
    to_next($c);
  }
  return False;
}

sub match_spp_rept {
  my ($c, $rule) = @_;
  my $gather = True;
  my $time   = 0;
  my ($rept, $atom) = flat($rule);
  my ($min,  $max)  = get_rept_time($rept);
  while ($time != $max) {
    my $cache = cache($c);
    my $match = match_spp_rule($c, $atom);
    if (is_false($match)) {
      if ($time < $min) { return False }
      reset_cache($c, $cache);
      return $gather;
    }
    $time++;
    $gather = gather_spp_match($gather, $match);
  }
  return $gather;
}

sub match_spp_look {
  my ($c,    $rule)      = @_;
  my ($rept, $atom_look) = flat($rule);
  my ($atom, $look)      = flat($atom_look);
  my ($min,  $max)       = get_rept_time($rept);
  my $gather = True;
  my $time   = 0;
  while ($time != $max) {
    my $cache = cache($c);
    my $match = match_spp_rule($c, $atom);
    if (is_false($match)) {
      if ($time > $min) { return False }
      reset_cache($c, $cache);
      $match = match_spp_rule($c, $look);
      if (is_false($match)) { return False }
      return gather_spp_match($gather, $match);
    }
    $time++;
    $gather = gather_spp_match($gather, $match);
    if ($time >= $min) {
      $cache = cache($c);
      $match = match_spp_rule($c, $look);
      if (not(is_false($match))) {
        return gather_spp_match($gather, $match);
      }
      reset_cache($c, $cache);
    }
  }
  return False;
}

sub match_spp_str {
  my ($c, $str) = @_;
  for my $char (split '', $str) {
    if ($char ne get_char($c)) { return False }
    to_next($c);
  }
  return $str;
}

sub match_spp_char {
  my ($c, $char) = @_;
  if ($char ne get_char($c)) { return False }
  to_next($c);
  return $char;
}

sub match_spp_chclass {
  my ($c, $atoms) = @_;
  my $char = get_char($c);
  for my $atom (@{ atoms($atoms) }) {
    if (match_spp_catom($atom, $char)) {
      to_next($c);
      return $char;
    }
  }
  return False;
}

sub match_spp_nclass {
  my ($c, $atoms) = @_;
  my $char = get_char($c);
  if ($char eq End) { return False }
  for my $atom (@{ atoms($atoms) }) {
    if (match_spp_catom($atom, $char)) { return False }
  }
  to_next($c);
  return $char;
}

sub match_spp_catom {
  my ($atom, $char)  = @_;
  my ($name, $value) = flat($atom);
  given ($name) {
    when ('Range') { return match_spp_range($value, $char) }
    when ('Cclass') {
      return is_match_spp_cclass($value, $char)
    }
    default { return $value eq $char }
  }
}

sub match_spp_cclass {
  my ($c, $cclass) = @_;
  my $char = get_char($c);
  if ($char eq End) { return False }
  if (is_match_spp_cclass($cclass, $char)) {
    to_next($c);
    return $char;
  }
  return False;
}

sub is_match_spp_cclass {
  my ($cchar, $char) = @_;
  given ($cchar) {
    when ('a') { return is_alpha($char) }
    when ('A') { return not(is_alpha($char)) }
    when ('d') { return is_digit($char) }
    when ('D') { return not(is_digit($char)) }
    when ('h') { return is_hspace($char) }
    when ('H') { return not(is_hspace($char)) }
    when ('l') { return is_lower($char) }
    when ('L') { return not(is_lower($char)) }
    when ('s') { return is_space($char) }
    when ('S') { return not(is_space($char)) }
    when ('u') { return is_upper($char) }
    when ('U') { return not(is_upper($char)) }
    when ('v') { return is_vspace($char) }
    when ('V') { return not(is_vspace($char)) }
    when ('w') { return is_words($char) }
    when ('W') { return not(is_words($char)) }
    when ('x') { return is_xdigit($char) }
    when ('X') { return not(is_xdigit($char)) }
    default    { say "unknown cclass: $cchar" }
  }
}

sub match_spp_range {
  my ($range, $char) = @_;
  my ($from,  $to)   = flat($range);
  return $from le $char && $char le $to;
}

sub match_spp_sym {
  my ($c, $name) = @_;
  my $value = get_spp_sym_value($c, $name);
  return match_spp_value($c, $value);
}

sub get_spp_sym_value {
  my ($c, $name) = @_;
  my $ns = $c->{'ns'};
  if (exists $ns->{$name}) { return $ns->{$name} }
  error("variable not define: <$name>.");
}

sub match_spp_value {
  my ($c,    $atom)  = @_;
  my ($name, $value) = flat($atom);
  given ($name) {
    when ('Array') {
      if (is_blank($value)) { return False }
      return match_spp_branch($c, $value)
    }
    when ('Str') { return match_spp_str($c, $value) }
  }
}

sub match_spp_call {
  my ($c, $call) = @_;
  my $value = get_spp_call_value($c, $call);
  return match_spp_value($c, $value);
}

sub get_spp_call_value {
  my ($c,    $call) = @_;
  my ($name, $args) = match($call);
  given ($name) {
    when ('my') { return eval_spp_my($c, $args) }
    when ('push') { return eval_spp_push($c, $args) }
    default { error("not implement: ($name..)") }
  }
}

sub eval_spp_my {
  my ($c,   $atoms) = @_;
  my ($sym, $value) = flat($atoms);
  if (is_sym($sym)) {
    my $name = value($sym);
    my $ns   = $c->{'ns'};
    $ns->{$name} = $value;
    return True;
  }
  error("only assign symbol!");
}

sub eval_spp_push {
  my ($c, $atoms) = @_;
  my $sym = name($atoms);
  if (is_sym($sym)) {
    my $name = value($sym);
    my $atoms_value = get_spp_atoms_value($c, $atoms);
    my ($array, $elem) = flat($atoms_value);
    $array = value($array);
    $array = epush($array, $elem);
    my $ns = $c->{'ns'};
    $ns->{$name} = cons('Array', $array);
    return True;
  }
  error('push only accept array symbol!');
}

sub get_spp_atom_value {
  my ($c,    $atom)  = @_;
  my ($name, $value) = flat($atom);
  given ($name) {
    when ('Array') {
      return get_spp_array_value($c, $value)
    }
    when ('Sym') { return get_spp_sym_value($c, $value) }
    when ('Str') { return $atom }
  }
}

sub get_spp_array_value {
  my ($c, $array) = @_;
  if (is_blank($array)) { return cons('Array', $array) }
  my $atoms = get_spp_atoms_value($c, $array);
  return cons('Array', $atoms);
}

sub get_spp_atoms_value {
  my ($c, $atoms) = @_;
  my $atoms_value = [];
  for my $atom (@{ atoms($atoms) }) {
    push @{$atoms_value}, get_spp_atom_value($c, $atom);
  }
  return estr($atoms_value);
}

sub name_spp_match {
  my ($name, $match, $pos) = @_;
  if (is_true($match)) { return $match }
  my $pos_str = estr_ints($pos);
  if (is_atom($match)) {
    return cons($name, cons($match), $pos_str);
  }
  return cons($name, $match, $pos_str);
}

sub gather_spp_match {
  my ($gather, $match) = @_;
  if (is_true($match))  { return $gather }
  if (is_true($gather)) { return $match }
  if (is_str($match)) {
    if (is_str($gather)) { return add($gather, $match) }
    return $gather;
  }
  if (is_str($gather)) { return $match }
  if (is_atom($gather)) {
    if (is_atom($match)) { return cons($gather, $match) }
    return eunshift($gather, $match);
  }
  if (is_atom($match)) { return epush($gather, $match) }
  return eappend($gather, $match);
}
1;
