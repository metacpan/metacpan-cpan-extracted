my $file = '../gl_const.h';
die "Unable to open '$file'" if (!open(FILE,$file));

foreach my $line (<FILE>)
{
  next if $line !~ m|i\(([^\)]+)\)|;
  print "$1\n";
}
close(FILE);
