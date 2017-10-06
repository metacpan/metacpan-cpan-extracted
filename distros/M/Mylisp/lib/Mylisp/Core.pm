package Mylisp::Core;

use 5.012;
no warnings "experimental";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(is_oper is_expr is_list is_atom_array
  is_call change_sufix is_update);

use File::Basename qw(fileparse);
use Spp::Builtin qw(is_atom to_json);
use Spp::Core qw(is_atom_name);

sub is_oper {
  my $atom = shift;
  if (is_atom_name($atom, 'Oper')) { return 1 }
  if (is_atom_name($atom, 'Sub')) {
    my $name = $atom->[1];
    return 1 if ($name ~~ [qw(x in eq ne lt gt le ge)]);
  }
  return 0;
}

sub is_expr {
  my $atom = shift;
  return is_atom_name($atom, 'Expr');
}

sub is_list {
  my $atom = shift;
  return is_atom_name($atom, 'List');
}

sub is_atom_array {
  my $atom = shift;
  return is_atom_name($atom, 'Array');
}

sub is_call {
  my $atom = shift;
  return is_atom_name($atom, 'Call');
}

sub change_sufix {
  my ($file, $from_sufix, $to_sufix) = @_;
  my @sufix = ($from_sufix);
  my ($name, $path) = fileparse($file, @sufix);
  return $path . $name . $to_sufix;
}

sub get_file_mtime {
  my $file = shift;
  if (not(-e $file)) {
    say "$file is not exists!";
  }
  else {
    return (stat($file))[9];
  }
}

sub is_update {
  my ($file, $to_file) = @_;
  my $file_mtime    = get_file_mtime($file);
  my $to_file_mtime = get_file_mtime($to_file);
  return ($file_mtime < $to_file_mtime);
}

1;
