package Mylisp::Type;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(new_lint get_type_parser get_type_cursor match_type pat_to_type_rule opt_pat_match match_type_rule match_type_rules match_type_branch match_type_token match_type_rept match_type_str match_type_end report type_grammar my_type_grammar opt_type_match map_opt_type_atom opt_type_atom opt_type_spec opt_type_atoms gather_type_branch opt_type_str is_branch type_rule_to_pat rules_to_pat branch_to_pat rept_to_pat);

use Spp;
use Spp::MatchRule;
use Spp::Tools;
use Spp::Builtin;
use Spp::Cursor;
use Spp::OptAst;
use Spp::LintAst;

sub new_lint {
  my $parser = get_type_parser();
  my $cursor = get_type_cursor();
  return {
    'offline' => '',
    'stack'   => [],
    'st'      => {},
    'ret'     => '',
    'parser'  => $parser,
    'cursor'  => $cursor
  };
}

sub get_type_parser {
  my $grammar = type_grammar();
  my $ast     = grammar_to_ast($grammar);
  lint_spp_ast($ast);
  my $parser = ast_to_table($ast);
  return $parser;
}

sub get_type_cursor {
  my $parser  = get_type_parser();
  my $grammar = my_type_grammar();
  my ($match, $ok) = match_text($parser, $grammar);
  if ($ok) {
    my $ast = opt_type_match($match);
    lint_spp_ast($ast);
    my $table = ast_to_table($ast);
    my $cursor = new_cursor('text', $table);
    return $cursor;
  }
  else { error($match) }
}

sub match_type {
  my ($t, $rule, $text) = @_;
  my $cursor = $t->{'cursor'};
  $cursor->{'text'} = add($text, End);
  $cursor->{'off'} = 0;
  return match_type_rule($cursor, $rule);
}

sub pat_to_type_rule {
  my ($t, $pat) = @_;
  my $table  = $t->{'parser'};
  my $rule   = $table->{'pat'};
  my $cursor = new_cursor($pat, $table);
  my $match  = match_spp_rule($cursor, $rule);
  if (is_false($match)) {
    report($t, "pattern: |$pat| could not to rule!");
  }
  return opt_pat_match($match);
}

sub opt_pat_match {
  my $match = shift;
  my $end = cons('End', 'End');
  if (is_atom($match)) {
    my $atom = opt_type_atom($match);
    return cons('Rules', cons($atom, $end));
  }
  my $atoms = opt_type_atoms($match);
  if (is_atom($atoms)) {
    return cons('Rules', cons($atoms, $end));
  }
  return cons('Rules', epush($atoms, $end));
}

sub match_type_rule {
  my ($c,    $rule)  = @_;
  if (elen($rule) < 2) {
    say see_ast($rule);
    croak('trace it...');
  }
  my ($name, $value) = flat($rule);
  given ($name) {
    when ('Rules') { return match_type_rules($c, $value) }
    when ('Branch') { return match_type_branch($c, $value) }
    when ('Rept') { return match_type_rept($c, $value) }
    when ('Str') { return match_type_str($c, $value) }
    when ('Token') { return match_type_token($c, $value) }
    when ('End') { return match_type_end($c, $value) }
    default {
      error("unknown rule: $name to match!");
      return False
    }
  }
}

sub match_type_rules {
  my ($c, $rules) = @_;
  my $return = False;
  for my $rule (@{ atoms($rules) }) {
    if (is_hspace(get_char($c))) { $c->{'off'}++ }
    my $match = match_type_rule($c, $rule);
    if (is_false($match)) { return False }
    $return = $match;
  }
  return $return;
}

sub match_type_branch {
  my ($c, $branch) = @_;
  my $off = $c->{'off'};
  for my $rule (@{ atoms($branch) }) {
    my $match = match_type_rule($c, $rule);
    if (not(is_false($match))) { return $match }
    $c->{'off'} = $off;
  }
  return False;
}

sub match_type_token {
  my ($c, $name) = @_;
  my $table = $c->{'ns'};
  my $rule  = $table->{$name};
  return match_type_rule($c, $rule);
}

sub match_type_rept {
  my ($c,    $rule) = @_;
  my ($rept, $atom) = flat($rule);
  my ($min,  $max)  = get_rept_time($rept);
  my $time = 0;
  while ($time != $max) {
    my $off = $c->{'off'};
    if (is_hspace(get_char($c))) { $c->{'off'}++ }
    my $match = match_type_rule($c, $atom);
    if (is_false($match)) {
      if ($time < $min) { return False }
      $c->{'off'} = $off;
      return True;
    }
    $time++;
  }
  return True;
}

sub match_type_str {
  my ($c, $str) = @_;
  for my $char (split '', $str) {
    if ($char ne get_char($c)) { return False }
    $c->{'off'}++;
  }
  return True;
}

sub match_type_end {
  my ($c, $end) = @_;
  if (get_char($c) eq End) { return True }
  return False;
}

sub report {
  my ($t, $message) = @_;
  my $offline = $t->{'offline'};
  my $line    = value($offline);
  error("error! line: $line $message");
  return False;
}

sub type_grammar {
  return <<'EOF'

    door    = |\s+ Spec|+ $ ;
    Spec    = Token \h+ '=' \h+ pat ;
    pat     = |\h Branch Token Str Rept|+ ;
    Branch  = '|' ;
    Token   = \a+ ;
    Str     = ':' \a+ ;
    Rept    = [+?] ;
    
EOF
}

sub my_type_grammar {
  return <<'EOF'

    door        = Bool|Int|StrOrArray|Ints|Map|Fn|Lint|Cursor
    Bool        = :Bool
    Str         = :Str|:String|:Lstr|:Char
    Int         = :Int
    Array       = :Array
    Ints        = :Ints
    Hash        = :Hash
    Table       = :Table
    Cursor      = :Cursor
    Lint        = :Lint
    Fn          = :Fn
    StrOrArray  = Str|Array
    Map         = Hash|Table
    
EOF
}

sub opt_type_match {
  my $match = shift;
  if (is_atom($match)) { return opt_type_atom($match) }
  return map_opt_type_atom($match);
}

sub map_opt_type_atom {
  my $atoms = shift;
  return estr(
    [map { opt_type_atom($_) } @{ atoms($atoms) }]);
}

sub opt_type_atom {
  my $atom = shift;
  my ($name, $value) = flat($atom);
  given ($name) {
    when ('Spec')   { return opt_type_spec($value) }
    when ('Str')    { return opt_type_str($value) }
    when ('Rept')   { return cons('rept', $value) }
    when ('Branch') { return cons('branch', $value) }
    when ('Token')  { return cons('Token', $value) }
    default         { say "unknown atom: |$name|" }
  }
}

sub opt_type_spec {
  my $atoms = shift;
  my ($token, $rules) = match($atoms);
  my $name = value($token);
  my $rule = opt_type_atoms($rules);
  return cons($name, $rule);
}

sub opt_type_atoms {
  my $atoms = shift;
  $atoms = map_opt_type_atom($atoms);
  $atoms = gather_spp_rept($atoms);
  $atoms = gather_type_branch($atoms);
  return $atoms;
}

sub gather_type_branch {
  my $atoms    = shift;
  my $branches = [];
  my $branch   = [];
  my $flag     = 0;
  my $count    = 0;
  for my $atom (@{ atoms($atoms) }) {
    if (is_branch($atom)) {
      if ($count > 1) {
        push @{$branches}, cons('Rules', estr($branch));
      }
      else { push @{$branches}, $branch->[0]; }
      $flag   = 1;
      $branch = [];
      $count  = 0;
    }
    else { push @{$branch}, $atom; $count++ }
  }
  if ($flag == 0) {
    if ($count == 1) { return $branch->[0] }
    else             { return cons('Rules', estr($branch)) }
  }
  if ($count > 1) {
    push @{$branches}, cons('Rules', estr($branch));
  }
  else { push @{$branches}, $branch->[0]; }
  return cons('Branch', estr($branches));
}

sub opt_type_str {
  my $str = shift;
  return cons('Str', rest_str($str));
}

sub is_branch {
  my $atom = shift;
  return is_atom_name($atom, 'branch');
}

sub type_rule_to_pat {
  my $pat = shift;
  my ($name, $value) = flat($pat);
  given ($name) {
    when ('Rules')  { return rules_to_pat($value) }
    when ('Branch') { return branch_to_pat($value) }
    when ('Rept')   { return rept_to_pat($value) }
    when ('Str')    { return ":$value" }
    when ('Token')  { return $value }
    when ('End')    { return '$' }
    default { say "unknown pat name: |$name| to str" }
  }
}

sub rules_to_pat {
  my $atoms = shift;
  my $strs =
    [map { type_rule_to_pat($_) } @{ atoms($atoms) }];
  return join ' ', @{$strs};
}

sub branch_to_pat {
  my $atoms = shift;
  my $strs =
    [map { type_rule_to_pat($_) } @{ atoms($atoms) }];
  return join '|', @{$strs};
}

sub rept_to_pat {
  my $rule = shift;
  my ($rept, $atom) = flat($rule);
  my $atom_str = type_rule_to_pat($atom);
  return add($atom_str, $rept);
}
1;
