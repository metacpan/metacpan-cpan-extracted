use File::Spec ();
require File::Spec::Win32;

sub main {
  my $path = shift;
  return unless defined $path;
  # A little hack is needed for UNC paths under File::Spec
  local $1;
	my $unc_name = $path =~ /^\\\\(\w+)/ ? $1 : undef;
  if (defined $unc_name) {
    # Let's have it treat it like a regular Win32 path
    $path =~ s/^\\\\$unc_name/C:/;
  }
	my @items = File::Spec::Win32->splitpath($path);
  if (defined $unc_name and @items and length $items[0]) {
    $items[0] = "\\\\$unc_name";
  }
  @items;
}

1;