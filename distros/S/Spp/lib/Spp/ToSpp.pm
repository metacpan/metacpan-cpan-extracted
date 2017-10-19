package Spp::ToSpp;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(ast_to_spp to_spp atoms_to_spp group_to_spp branch_to_spp rept_to_spp look_to_spp chclass_to_spp nclass_to_spp str_to_spp cclass_to_spp char_to_spp cchar_to_spp till_to_spp not_to_spp range_to_spp);

use Spp::Builtin;
use Spp::Tools;

sub ast_to_spp {
  my $ast  = shift;
  my $strs = [];
  for my $spec (@{ atoms($ast) }) {
    my ($name, $rule) = flat($spec);
    my $rule_str = to_spp($rule);
    push @{$strs}, "$name = $rule_str";
  }
  return join ';', @{$strs};
}

sub to_spp {
  my $rule = shift;
  my ($name, $value) = flat($rule);
  given ($name) {
    when ('Rules')   { return atoms_to_spp($value) }
    when ('Group')   { return group_to_spp($value) }
    when ('Branch')  { return branch_to_spp($value) }
    when ('Rept')    { return rept_to_spp($value) }
    when ('Look')    { return look_to_spp($value) }
    when ('Chclass') { return chclass_to_spp($value) }
    when ('Nclass')  { return nclass_to_spp($value) }
    when ('Str')     { return str_to_spp($value) }
    when ('Char')    { return char_to_spp($value) }
    when ('Cclass')  { return cclass_to_spp($value) }
    when ('Till')    { return till_to_spp($value) }
    when ('Not')     { return not_to_spp($value) }
    when ('Range')   { return range_to_spp($value) }
    when ('Cchar')   { return cchar_to_spp($value) }
    default          { return $value }
  }
}

sub atoms_to_spp {
  my $atoms = shift;
  return join ' ',
    @{ [map { to_spp($_) } @{ atoms($atoms) }] };
}

sub group_to_spp {
  my $rule = shift;
  return add("(", atoms_to_spp($rule), ")");
}

sub branch_to_spp {
  my $branch = shift;
  return add("|", atoms_to_spp($branch), "|");
}

sub rept_to_spp {
  my $rule = shift;
  my ($rept, $atom) = flat($rule);
  return add(to_spp($atom), $rept);
}

sub look_to_spp {
  my $rule = shift;
  my ($rept, $atom_look) = flat($rule);
  my ($atom, $look)      = flat($atom_look);
  return add(to_spp($atom), $rept, to_spp($look));
}

sub chclass_to_spp {
  my $atoms = shift;
  return add("[", atoms_to_spp($atoms), "]");
}

sub nclass_to_spp {
  my $atoms = shift;
  return add("[^", atoms_to_spp($atoms), "]");
}

sub str_to_spp {
  my $str = shift;
  return add("'", $str, "'");
}

sub cclass_to_spp {
  my $cclass = shift;
  return add("\\", $cclass);
}

sub char_to_spp {
  my $char = shift;
  given ($char) {
    when ("\n") { return '\n' }
    when ("\r") { return '\r' }
    when ("\t") { return '\t' }
    when ("\\") { return '\\' }
    when ('"')  { return '\"' }
    when ("'")  { return '\'' }
    default     { return "'$char'" }
  }
}

sub cchar_to_spp {
  my $char = shift;
  given ($char) {
    when ("\n") { return '\n' }
    when ("\r") { return '\r' }
    when ("\t") { return '\t' }
    when ("\\") { return '\\' }
    when ('-')  { return '\-' }
    when (']')  { return '\]' }
    when ('^')  { return '\^' }
    default     { return $char }
  }
}

sub till_to_spp {
  my $rule = shift;
  return add("~", to_spp($rule));
}

sub not_to_spp {
  my $rule = shift;
  return add("!", to_spp($rule));
}

sub range_to_spp {
  my $atom = shift;
  return join '-', @{ atoms($atom) };
}
1;
