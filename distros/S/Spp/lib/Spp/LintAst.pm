package Spp::LintAst;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(lint_ast ast_to_table);

use 5.012;
no warnings "experimental";
use Spp::Builtin;

# lint namespace: Top, all defined token is used
sub lint_ast {
   my $ast = shift;
   my $ns = ast_to_table($ast);
   $ns->{':error'} = 0;
   my $door = $ast->[0][0];
   check_token($door, $ns);
   for my $name (keys %{$ns}) {
      next if $name ~~ ['text', ':error'];
      next if start_with($name, '*');
      my $check_name = '*' . $name;
      if (!exists $ns->{$check_name}) {
         next if $name eq $door;
         say "warn! rule: <$name> not used!";
         $ns->{':error'}++;
      }
   }
   return not($ns->{':error'});
}

sub check_token {
   my ($name, $ns) = @_;
   if (!exists($ns->{$name})) {
      say "not exists token: <$name>";
      $ns->{':error'}++;
   }
   my $rule       = $ns->{$name};
   my $check_name = '*' . $name;
   if (!exists($ns->{$check_name})) {
      $ns->{$check_name} = 1;
      check_rule($rule, $ns);
   }
}

sub check_rule {
   my ($rule, $ns) = @_;
   if (is_str($rule)) { return 1 }
   my ($name, $atoms) = @{$rule};
   given ($name) {
      when (['Ctoken', 'Ntoken', 'Rtoken']) {
         check_token($atoms, $ns)
      }
      when (['Rept', 'Look']) {
         for my $atom (@{$atoms}) {
            check_rule($atom, $ns)
         }
      }
      when (['Not', 'Till']) { check_rule($atoms, $ns) }
      when (['Rules', 'Group', 'Branch', 'Lbranch']) {
         for my $atom (@{$atoms}) { check_rule($atom, $ns) }
      }
      when (['Any','Str','Char','Cclass','Assert','Chclass',
             'Nchclass','Expr','Sym']) { return 1 }
      default { 
         say "miss rule: <$name> check";
         $ns->{':error'}++;
      }
   }
}

sub ast_to_table {
   my $ast   = shift;
   my $table = {};
   for my $spec (@{$ast}) {
      my ($name, $rule) = @{$spec};
      if (exists $table->{$name}) {
         say "repeat token define $name";
      }
      $table->{$name} = $rule;
   }
   return $table;
}

1;
