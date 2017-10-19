package Spp::LintAst;

use 5.012;
no warnings 'experimental';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(lint_spp_ast lint_spp_token lint_spp_rule lint_spp_atoms);

use Spp::Builtin;
use Spp::Tools;

sub lint_spp_ast {
  my $ast = shift;
  my $ns  = ast_to_table($ast);
  lint_spp_token('door', $ns);
  for my $name (keys %{$ns}) {
    next if $name eq 'text';
    next if start_with($name, ":");
    my $lint_name = add(":", $name);
    if (not(exists $ns->{$lint_name})) {
      next if $name eq 'door';
      say "warn! rule: <$name> not used!";
    }
  }
}

sub lint_spp_token {
  my ($name, $ns) = @_;
  if (not(exists $ns->{$name})) {
    say "not exists token: <$name>";
  }
  else {
    my $rule = $ns->{$name};
    my $lint_name = add(":", $name);
    if (not(exists $ns->{$lint_name})) {
      $ns->{$lint_name} = 'yes';
      lint_spp_rule($rule, $ns);
    }
  }
}

sub lint_spp_rule {
  my ($rule, $ns) = @_;
  if (is_str($rule)) { return True }
  my ($name, $atoms) = flat($rule);
  given ($name) {
    when ('Ctoken') { lint_spp_token($atoms, $ns) }
    when ('Ntoken') { lint_spp_token($atoms, $ns) }
    when ('Rtoken') { lint_spp_token($atoms, $ns) }
    when ('Token')  { lint_spp_token($atoms, $ns) }
    when ('Not')  { lint_spp_rule($atoms, $ns) }
    when ('Till') { lint_spp_rule($atoms, $ns) }
    when ('Rept')   { lint_spp_atoms($atoms, $ns) }
    when ('Look')   { lint_spp_atoms($atoms, $ns) }
    when ('Rules')  { lint_spp_atoms($atoms, $ns) }
    when ('Group')  { lint_spp_atoms($atoms, $ns) }
    when ('Branch') { lint_spp_atoms($atoms, $ns) }
    when ('Any')    { return True }
    when ('Str')    { return True }
    when ('Char')   { return True }
    when ('Cclass') { return True }
    when ('Assert') { return True }
    when ('Chclass') { return True }
    when ('Nclass')  { return True }
    when ('Space')   { return True }
    when ('End')     { return True }
    default          { say "miss rule: <$name> check" }
  }
  return True;
}

sub lint_spp_atoms {
  my ($atoms, $ns) = @_;
  for my $atom (@{ atoms($atoms) }) {
    lint_spp_rule($atom, $ns);
  }
  return True;
}
1;
