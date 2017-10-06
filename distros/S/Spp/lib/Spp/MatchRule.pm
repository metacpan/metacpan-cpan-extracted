package Spp::MatchRule;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(match_rule);

use Spp::Builtin;
use Spp::Core;
use Spp::Cursor;

sub match_rule {
   my ($rule, $cursor) = @_;
   my ($name, $atom)  = @{$rule};
   given ($name) {
      when ('Rules')    { match_group($atom, $cursor)   }
      when ('Group')    { match_group($atom, $cursor)   }
      when ('Branch')   { match_branch($atom, $cursor)  }
      when ('Rept')     { match_rept($atom, $cursor)    }
      when ('Look')     { match_look($atom, $cursor)    }
      when ('Cclass')   { match_cclass($atom, $cursor)  }
      when ('Chclass')  { match_chclass($atom, $cursor) }
      when ('Nchclass') { match_nchclass($atom, $cursor)}
      when ('Str')      { match_str($atom, $cursor)     }
      when ('Char')     { match_char($atom, $cursor)    }
      when ('Assert')   { match_assert($atom, $cursor)  }
      when ('Not')      { match_not($atom, $cursor)     }
      when ('Till')     { match_till($atom, $cursor)    }
      when ('Rtoken')   { match_rtoken($atom, $cursor)  }
      when ('Ctoken')   { match_ctoken($atom, $cursor)  }
      when ('Ntoken')   { match_ntoken($atom, $cursor)  }
      when ('Any')      { match_any($atom, $cursor)     }
      when ('Expr')     { match_expr($atom, $cursor)    }
      when ('Sym')      { match_sym($atom, $cursor)     }
      default { 
         error("unknown rule type |$name|!")
      }
   }
}

sub match_any {
   my ($any, $cursor) = @_;
   my $char = $cursor->get_char;
   if ($char eq chr(0)) { return False }
   $cursor->to_next;
   return $char;
}

sub match_assert {
   my ($assert, $cursor) = @_;
   given ($assert) {
      when ('^') {
         return True if $cursor->off == 0;
         return False;
      }
      when ('$') {
         return True if $cursor->get_char eq chr(0);
         return False;
      }
      when ('^^') {
         return True if $cursor->pre_char eq "\n";
         return True if $cursor->off == 0;
         return False;
      }
      when ('$$') {
         return True if $cursor->get_char eq "\n";
         return True if $cursor->get_char eq chr(0);
         return False;
      }
      default { error("error assert char: <$assert>!") }
   }
}

sub match_group {
   my ($rules, $cursor) = @_;
   my $gather = True;
   for my $rule (@{$rules}) {
      my $match = match_rule($rule, $cursor);
      return False if is_false($match);
      $gather = gather_match($gather, $match);
   }
   return $gather;
}

sub match_branch {
   my ($branch, $cursor) = @_;
   my $cache     = $cursor->cache;
   my $max_match = False;
   my $max_cache = $cache;
   my $max_off   = -1;
   for my $rule (@{$branch}) {
      my $match = match_rule($rule, $cursor);
      if (!is_false($match)) {
         if ($cursor->off > $max_off) {
            $max_off = $cursor->off;
            $max_cache = $cursor->cache;
            $max_match = $match;
         }
      }
      $cursor->reset_cache($cache);
   }
   $cursor->reset_cache($max_cache);
   return $max_match;
}

sub match_ntoken {
   my ($name, $cursor) = @_;
   my $rule  = $cursor->{'ns'}{$name};
   my $from  = $cursor->off;
   my $cache = $cursor->cache;
   my $match = match_rule($rule, $cursor);
   return $match if is_bool($match);
   my $len   = $cursor->off - $from;
   if ($len > 0) {
      my $str   = substr($cursor->str, $from, $len);
      my $cname = '$' . $name;
      $cursor->{'ns'}{$cname} = ['Str', $str];
   }
   push @{$cache}, $len;
   return name_match($name, $match, $cache);
}

sub match_ctoken {
   my ($name, $cursor) = @_;
   my $rule  = $cursor->{'ns'}{$name};
   my $from  = $cursor->off;
   my $match = match_rule($rule, $cursor);
   return $match if is_bool($match);
   my $len   = $cursor->off - $from;
   if ($len > 0) {
      my $str   = substr($cursor->str, $from, $len);
      my $cname = '$' . $name;
      $cursor->{'ns'}{$cname} = ['Str', $str];
   }
   return $match;
}

sub match_rtoken {
   my ($name, $cursor) = @_;
   my $rule = $cursor->{'ns'}{$name};
   my $match = match_rule($rule, $cursor);
   return False if is_false($match);
   return True;
}

sub match_not {
   my ($rule, $cursor) = @_;
   my $cache = $cursor->cache;
   my $match = match_rule($rule, $cursor);
   if (is_false($match)) {
      $cursor->reset_cache($cache);
      return True;
   }
   return False;
}

sub match_till {
   my ($rule, $cursor) = @_;
   my @buf = ();
   while ($cursor->off < $cursor->len) {
      my $char = $cursor->get_char;
      my $cache = $cursor->cache;
      my $match = match_rule($rule, $cursor);
      if (!is_false($match)) {
         my $gather_str = join '', @buf;
         return gather_match($gather_str, $match);
      }
      push @buf, $char;
      $cursor->reset_cache($cache);
      $cursor->to_next;
   }
   return False;
}

sub match_rept {
   my ($rule, $cursor) = @_;
   my $gather = True;
   my $time   = 0;
   my ($rept, $atom) = @{$rule};
   my ($min,  $max)  = get_rept_time($rept);
   while ($time != $max) {
      my $cache = $cursor->cache;
      my $match = match_rule($atom, $cursor);
      if (is_false($match)) {
         return False if $time < $min;
         $cursor->reset_cache($cache);
         return $gather;
      }
      $time++;
      $gather = gather_match($gather, $match);
   }
   return $gather;
}

sub match_look {
   my ($rule, $cursor) = @_;
   my ($rept, $atom, $look) = @{$rule};
   my ($min, $max) = get_rept_time($rept);
   my ($gather, $time)   = (True, 0);
   while ($time != $max) {
      my $cache = $cursor->cache;
      my $match = match_rule($atom, $cursor);
      if (is_false($match)) {
         return False if $time > $min;
         $cursor->reset_cache($cache);
         $match = match_rule($look, $cursor);
         return False if is_false($match);
         return gather_match($gather, $match);
      }
      $time++;
      $gather = gather_match($gather, $match);
      if ($time >= $min) {
         $cache = $cursor->cache;
         $match = match_rule($look, $cursor);
         if (!is_false($match)) {
            return gather_match($gather, $match)
         }
         $cursor->reset_cache($cache);
      }
   }
   return False;
}

sub match_str {
   my ($str, $cursor) = @_;
   for my $char (split('', $str)) {
      if ($char ne $cursor->get_char) { return False }
      $cursor->to_next;
   }
   return $str;
}

sub match_char {
   my ($char, $cursor) = @_;
   return False if $char ne $cursor->get_char;
   $cursor->to_next;
   return $char;
}

sub match_chclass {
   my ($atoms, $cursor) = @_;
   my $char = $cursor->get_char;
   for my $atom (@{$atoms}) {
      if (match_catom($atom, $char)) {
         $cursor->to_next;
         return $char;
      }
   }
   return False;
}

sub match_nchclass {
   my ($atoms, $cursor) = @_;
   my $char = $cursor->get_char;
   return False if $char eq chr(0);
   for my $atom (@{$atoms}) {
      return False if match_catom($atom, $char);
   }
   $cursor->to_next;
   return $char;
}

sub match_catom {
   my ($atom, $char)  = @_;
   my ($name, $value) = @{$atom};
   given ($name) {
      when ("Range") { match_range($value, $char) }
      when ("Cclass") { is_match_cclass($value, $char) }
      when ("Char") { return $value eq $char }
   }
}

sub match_cclass {
   my ($cclass, $cursor) = @_;
   my $char = $cursor->get_char;
   return False if $char eq chr(0);
   if (is_match_cclass($cclass, $char)) {
      $cursor->to_next;
      return $char;
   }
   return False;
}

sub is_match_cclass {
   my ($cchar, $char) = @_;
   given ($cchar) {
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
   }
}

sub match_range {
   my ($range, $char) = @_;
   my ($from,  $to) = @{$range};
   return ($from le $char && $char le $to);
}

sub match_expr {
   my ($expr, $cursor) = @_;
   my $atom = eval_expr($expr, $cursor);
   return match_atom($atom, $cursor);
}

sub match_sym {
   my ($name, $cursor) = @_;
   my $value = eval_sym($name, $cursor);
   return match_atom($value, $cursor);
}

sub match_atom {
   my ($atom, $cursor) = @_;
   return $atom if is_bool($atom);
   my ($name, $value) = @{$atom};
   return False if len($value) == 0;
   given ($name) {
      when ('Array') {
         return match_branch($value, $cursor)
      }
      when ('Str') {
        return match_str($value, $cursor)
     }
   }
}

sub name_match {
   my ($name, $match, $pos) = @_;
   if (is_true($match)) { return $match }
   if (is_atom($match)) { return [$name, [$match], $pos] }
   return [$name, $match, $pos];
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
   my ($atom, $cursor) = @_;
   my ($name, $value) = @{$atom};
   given ($name) {
      when ('Str')   { return $atom }
      when ('Sym')   { return eval_sym($value, $cursor) }
      when ('Expr')  { return eval_expr($value, $cursor) }
      when ('Array') { return eval_array($value, $cursor) }
   }
}

sub eval_sym {
   my ($name, $cursor) = @_;
   if (exists $cursor->{'ns'}{$name}) {
      return $cursor->{'ns'}{$name};
   }
   $cursor->error("variable not define: <$name>.");
}

sub eval_expr {
   my ($expr, $cursor) = @_;
   my $name = shift @{$expr};
   given ($name) {
      when ('push') { eval_push($expr, $cursor) }
      when ('my')   { eval_my($expr, $cursor) }
      when ('say')  { eval_say($expr, $cursor) }
      default { 
         $cursor->error("not implement action: <$name>.");
      }
   }
}

sub eval_array {
   my ($array, $cursor) = @_;
   if (len($array) == 0) {
      return ['Array', $array]
   }
   my $atoms = eval_atoms($array, $cursor);
   return ['Array', $atoms];
}

sub eval_push {
   my ($atoms, $cursor) = @_;
   my $sym = $atoms->[0];
   if (is_sym($sym)) {
      my $eval_atoms = eval_atoms($atoms, $cursor);
      my ($array, $element) = @{$eval_atoms};
      push @{ $array->[1] }, $element;
      my $name = $sym->[1];
      $cursor->{'ns'}{$name} = $array;
      return True;
   }
   $cursor->error('push only accept array symbol!');
}

sub eval_my {
   my ($atoms, $cursor) = @_;
   my $sym = $atoms->[0];
   my $value = eval_atom($atoms->[1], $cursor);
   if (is_sym($sym)) {
      my $name = $sym->[1];
      $cursor->{'ns'}{$name} = $value;
      return True;
   }
   $cursor->error('only assign symbol!');
}

sub eval_say {
   my ($atoms, $cursor) = @_;
   my $eval_atoms = eval_atoms($atoms, $cursor);
   my $str = $eval_atoms->[0];
   if (is_atom_str($str)) {
      say $str->[1];
      return True;
   }
   my $type = $str->[0];
   $cursor->error("say only accept Str: <$type>");
}

sub eval_atoms {
   my ($atoms, $cursor) = @_;
   return [ map { eval_atom($_, $cursor) } @{$atoms} ];
}

1;
