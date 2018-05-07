package Mylisp;

use 5.012;
use experimental 'switch';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(SppRepl GrammarToAst Parse MyToAst AstToTable Spp LintSppAst UpdateSppAst);

our $VERSION = '3.00';

use Mylisp::Builtin;
use Mylisp::Estr;
use Mylisp::SppAst;
use Mylisp::SppGrammar;
use Mylisp::Match;
use Mylisp::OptSppAst;
use Mylisp::MyGrammar;
use Mylisp::OptMyAst;

sub SppRepl {
  my $table = get_spp_table();
  say 'This is Spp REPL, type enter to exit.';
  while (1) {
    print '>> ';
    my $line = <STDIN>;
    $line = trim($line);
    exit() if $line eq '';
    my ($match,$ok) = MatchTable($table,$line);
    if ($ok) {
      my $ast = clean_ast($match);
      say estr_to_json($ast);
      my $opt_ast = OptSppAst($ast);
      say estr_to_json($opt_ast);
    }
    else {
      say $match;
    }
  }
}

sub GrammarToAst {
  my $grammar = shift;
  my $spp_ast = GetSppAst();
  my $table = AstToTable($spp_ast);
  my ($match,$ok) = MatchTable($table,$grammar);
  if (not($ok)) {
    error($match);
  }
  my $ast = OptSppAst($match);
  LintSppAst($ast);
  return $ast
}

sub Parse {
  my ($grammar_file,$text_file) = @_;
  my $grammar = read_file($grammar_file);
  my $text = read_file($text_file);
  my $ast = GrammarToAst($grammar);
  my $table = AstToTable($ast);
  my ($match,$ok) = MatchTable($table,$text);
  if (not($ok)) {
    error($match);
  }
  my $clean_ast = clean_ast($match);
  return estr_to_json($clean_ast)
}

sub get_my_table {
  my $grammar = GetMyGrammar();
  my $ast = GrammarToAst($grammar);
  return AstToTable($ast)
}

sub MyToAst {
  my $code = shift;
  my $table = get_my_table();
  my ($match,$ok) = MatchTable($table,$code);
  if (not($ok)) {
    error($match);
  }
  return OptMyAst($match)
}

sub AstToTable {
  my $ast = shift;
  my $table = {};
  for my $spec (@{atoms($ast)}) {
    my ($name,$rule) = flat($spec);
    if (exists $table->{$name}) {
      say "Repeat define token: |$name|";
    }
    $table->{$name} = $rule;
  }
  return $table
}

sub get_spp_table {
  my $ast = GetSppAst();
  return AstToTable($ast)
}

sub Spp {
  my $file = shift;
  my $grammar = read_file($file);
  my $ast = GrammarToAst($grammar);
  return estr_to_json($ast)
}

sub LintSppAst {
  my $ast = shift;
  my $table = {};
  my $values = [];
  for my $atom (@{atoms($ast)}) {
    my ($name,$value) = flat($atom);
    if (exists $table->{$name}) {
      say "repeat define rule: |$name|";
    }
    else {
      $table->{$name} = 'define';
      apush($values,$value);
    }
  }
  for my $rule (@{$values}) {
    lint_spp_rule($rule,$table);
  }
  for my $name (keys %{$table}) {
    next if $name eq 'door';
    my $value = $table->{$name};
    if ($value eq 'define') {
      say "not used rule: |$name|";
    }
  }
}

sub lint_spp_rule {
  my ($rule,$t) = @_;
  my ($name,$atoms) = flat($rule);
  if (not($name ~~ ['Any','Str','Char','Cclass','Assert','Chclass','Nclass','Blank'])) {
    given ($name) {
      when ('Ctoken') {
        lint_spp_token($atoms,$t);
      }
      when ('Ntoken') {
        lint_spp_token($atoms,$t);
      }
      when ('Rtoken') {
        lint_spp_token($atoms,$t);
      }
      when ('Till') {
        lint_spp_rule($atoms,$t);
      }
      when ('Rept') {
        lint_spp_rule(value($atoms),$t);
      }
      when ('Branch') {
        lint_spp_atoms($atoms,$t);
      }
      when ('Group') {
        lint_spp_atoms($atoms,$t);
      }
      when ('Rules') {
        lint_spp_atoms($atoms,$t);
      }
      default {
        say "lint spp rule-name? |$name|";
      }
    }
  }
}

sub lint_spp_atoms {
  my ($atoms,$table) = @_;
  for my $atom (@{atoms($atoms)}) {
    lint_spp_rule($atom,$table);
  }
}

sub lint_spp_token {
  my ($name,$table) = @_;
  if (exists $table->{$name}) {
    $table->{$name} = 'used';
  }
  else {
    say "not exists rule: |$name|";
  }
}

sub UpdateSppAst {
  my $grammar = GetSppGrammar;
  my $ast = GrammarToAst($grammar);
  my $json = estr_to_json(clean_ast($ast));
  my $code = ast_to_package($json);
  my $ast_file = 'SppAst.my';
  write_file($ast_file,$code);
  say "update ok! write file $ast_file";
}

sub ast_to_package {
  my $estr = shift;
  my $head = '(package Mylisp::SppAst)';
  my $use = '(use Mylisp::Estr)';
  my $func = "(func (GetSppAst) (-> Str) (return (json-to-estr '''";
  return add($head,$use,$func,$estr,"''')))")
}
1;
