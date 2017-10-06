package Spp;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(spp_to_ast ast_to_parser spp_to_parser
     match_text spp_to_spp parse lint_ast see_ast);

our $VERSION = '2.0';
use Spp::Builtin;
use Spp::Ast;
use Spp::Grammar qw(get_grammar);
use Spp::Cursor;
use Spp::Estr qw(to_estr from_estr flat atoms);
use Spp::MatchRule qw(match_rule);
use Spp::OptAst qw(opt_ast);
use Spp::ToSpp qw(ast_to_spp);

sub ast_to_parser {
   my $ast   = shift;
   my $table = {};
   for my $spec (@{$ast}) {
      my ($name, $rule) = @{$spec};
      if (exists $table->{$name}) {
         say "repeated key: |$name|.";
      }
      $table->{$name} = $rule;
   }
   my $door = $ast->[0][0];
   return [$door, $table];
}

sub get_spp_parser {
   my $json_ast = Spp::Ast::get_ast();
   my $ast = from_json($json_ast);
   lint_ast($ast);
   return ast_to_parser($ast);
}

sub spp_to_ast {
   my $grammar   = shift;
   my $parser = get_spp_parser();
   my $match = match_text($parser, $grammar);
   my $ast = opt_ast($match);
   lint_ast($ast);
   return $ast;
 }

sub spp_to_parser {
   my $grammar = shift;
   my $ast  = spp_to_ast($grammar);
   $ast = clean_ast($ast);
   lint_ast($ast);
   return ast_to_parser($ast);
}

sub match_text {
   my ($parser, $text) = @_;
   my ($door, $ns) = @{$parser};
   my $rule = $ns->{$door};
   my $cursor = Spp::Cursor->new($text, $ns);
   my $match = match_rule($rule, $cursor);
   if (is_false($match)) {
      say $cursor->max_report;
      exit();
   }
   return $match;
}

sub spp_to_spp {
   my $str    = shift;
   my $parser = get_spp_parser();
   my $match = match_text($parser, $str);
   my $ast = opt_ast($match);
   return ast_to_spp($ast);
}

sub parse {
   my ($grammar, $code) = @_;
   my $parser = spp_to_parser($grammar);
   my $match = match_text($parser, $code);
   return $match if is_true($match);
   return see_ast($match);
}

sub lint_ast {
   my $ast = shift;
   my $parser = ast_to_parser($ast);
   my ($door, $ns) = @{$parser}; 
   check_token($door, $ns);
   for my $name (keys %{$ns}) {
      next if $name eq 'text';
      next if $name eq $door;
      next if start_with($name, '*');
      my $cname = '*' . $name;
      if (!exists $ns->{$cname}) {
         say "warn! rule: <$name> not used!";
      }
   }
}

sub check_token {
   my ($name, $ns) = @_;
   if (!exists($ns->{$name})) {
      say "not exists token: <$name>";
   }
   my $rule  = $ns->{$name};
   my $cname = '*' . $name;
   if (!exists($ns->{$cname})) {
      $ns->{$cname} = 1;
      check_rule($rule, $ns);
   }
}

sub check_rule {
   my ($rule, $ns) = @_;
   if (is_str($rule)) { return 1 }
   my ($name, $atoms) = @{$rule};
   given ($name) {
      when ([qw(Ctoken Ntoken Rtoken)]) {
         check_token($atoms, $ns)
      }
      when ([qw(Not Till)]) { 
         check_rule($atoms, $ns)
      }
      when ([qw(Rept Look Rules Group Branch)]) {
         for my $atom (@{$atoms}) {
            check_rule($atom, $ns)
         }
      }
   }
}

1;
