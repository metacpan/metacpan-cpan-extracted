use File::Spec ();
require File::Spec::Win32;

sub main {
  my $path = shift;
  # A little hack is needed for UNC paths under File::Spec
  my $is_unc = $path =~ /^\\\\/ ? 1 : 0;
	my @items = File::Spec::Win32->splitdir($path);
  if ($is_unc and @items >= 3 and length($items[0]) == 0 and length($items[1]) == 0) {
    @items = ('\\\\'.$items[2], @items[3..$#items]);
  }
  @items;
}

1;