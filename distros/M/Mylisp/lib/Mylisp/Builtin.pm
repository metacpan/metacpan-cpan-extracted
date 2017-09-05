package Mylisp::Builtin;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(uuid zip looks_like_number load_module);

use 5.012;
use List::MoreUtils qw(mesh);
use Scalar::Util qw(looks_like_number);
use Spp::Builtin;
use File::Spec;

sub uuid { return sclar(rand()) }

sub zip {
   my ($arr_one, $arr_two) = @_;
   return [mesh(@{$arr_one}, @{$arr_two})];
}

sub load_module {
  my $module_str = shift;
  my @dirs = split '::', $module_str;
  my $file = pop @dirs;
  my $module_file = $file . '.spp';
  my $path = File::Spec->catfile(@dirs, $module_file);
  return read_file($path);
}

1;
