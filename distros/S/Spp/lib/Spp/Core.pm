package Spp::Core;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(ast_to_table concat start_with end_with
  to_end append is_atom_name is_false
  is_match is_true is_bool is_atom_sym is_atom_token
  is_atom_tillnot is_atom_str is_atom_expr clean_ast);

use Spp::Builtin;

sub ast_to_table {
   my $ast   = shift;
   my $table = {};
   for my $spec (@{$ast}) {
      my ($name, $rule) = @{$spec};
      if (exists $table->{$name}) {
         say "repeated key: |$name|.";
      }
      $table->{$name} = $rule;
   }
   return $table;
}

sub start_with {
   my ($str, $start) = @_;
   return 1 if index($str, $start) == 0;
   return 0;
}

sub end_with {
   my ($str, $end) = @_;
   my $len = length($end);
   return substr($str, -$len) eq $end;
}

sub to_end {
   my $str   = shift;
   my @chars = ();
   for my $char (split '', $str) {
      last if $char eq "\n";
      push @chars, $char;
   }
   return join('', @chars);
}

sub is_atom_name {
   my ($atom, $name) = @_;
   return (is_atom($atom) and $atom->[0] eq $name);
}

sub is_false {
   my $atom = shift;
   return is_atom_name($atom, 'false');
}

sub is_match {
   my $atom = shift;
   return not(is_false($atom));
}

sub is_true {
   my $atom = shift;
   return is_atom_name($atom, 'true');
}

sub is_bool {
   my $atom = shift;
   return (is_false($atom) or is_true($atom));
}

sub is_atom_sym {
   my $atom = shift;
   return is_atom_name($atom, 'Sym');
}

sub is_atom_token {
   my $atom = shift;
   return is_atom_name($atom, 'Token');
}

sub is_atom_tillnot {
   my $s = shift;
   if (is_atom($s)) {
      return 1 if $s->[0] eq 'Till';
      return 1 if $s->[0] eq 'Not';
   }
   return 0;
}

sub is_atom_str {
   my $atom = shift;
   return is_atom_name($atom, 'Str');
}

sub is_atom_expr {
   my $atom = shift;
   return is_atom_name($atom, 'Expr');
}

1;
