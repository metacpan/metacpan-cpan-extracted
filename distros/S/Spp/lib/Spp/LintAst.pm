# Copyright 2016 The Michael Song. All rights rberved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

package Spp::LintAst;

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(lint_ast);

use 5.012;
no warnings "experimental";
use Spp::Tools;
use Spp::IsAtom;

# lint namespace: Top, all defined token is used
sub lint_ast {
   my $ast = shift;
   # say to_json($ast);
   my $door = $ast->[0][0];
   my $ns   = {};
   for my $spec (@{$ast}) {
      my ($name, $rule) = @{$spec};
      # say "get $name key";
      $ns->{$name} = $rule;
   }
   # lint ast from door
   check_token($door, $ns);

   # check used rule name
   for my $name (keys %{$ns}) {
      next if $name ~~ ['text', 'file'];
      next if start_with($name, '*');
      my $check_name = '*' . $name;
      if (!exists $ns->{$check_name}) {
         next if $name eq $door;
         say("warn! rule: <$name> not used");
      }
   }
   say('Finish Lint ns!');
}

sub check_token {
   my ($name, $ns) = @_;
   # say "check token: <$name>";
   if (!exists($ns->{$name})) {
      say("not exists token: <$name>");
   }
   my $rule       = $ns->{$name};
   my $check_name = '*' . $name;
   if (!exists($ns->{$check_name})) {
      # say "not exists check name: $check_name";
      # say to_json($rule);
      $ns->{$check_name} = 1;
      check_rule($rule, $ns);
   }
}

sub check_rule {
   my ($rule, $ns) = @_;
   return 1 if is_chars($rule);
   my ($name, $value) = @{$rule};
   # say to_json($rule);
   if ($name =~ /token$/) {
      # say "check token: <$value>";
      check_token($value, $ns);
   }
   elsif ($name ~~ [ 'Rept', 'Look' ]) {
      for my $atom (@{$value}) {
         check_rule($atom, $ns);
      }
   }
   elsif ($name ~~ ['Not', 'Till']) {
      check_rule($value, $ns);
   }
   elsif ($name ~~ ['Rules', 'Group', 'Branch', 'Lbranch']) {
      for my $atom (@{$value}) {
         # say "check rule: <$name>";
         # say to_json($atom);
         check_rule($atom, $ns);
      }
   }
   else {
      next if $name ~~ 
         ['Any','Str','Char','Cclass','Assert','Chclass',
            'Nchclass', 'Expr', 'Sym'];
      say "miss rule: <$name> check";
   }
}

1;
