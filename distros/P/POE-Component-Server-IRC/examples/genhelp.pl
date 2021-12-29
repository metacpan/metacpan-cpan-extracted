use 5.012;
use strict;
use warnings;
use File::Glob ':bsd_glob';
my $dir = shift || die;
chdir $dir or die "$!\n";
my @items = bsd_glob("*");
foreach my $item (@items) {
  next if $item =~ m!^Makefile!;
  say "\nsub _$item {";
  say q{  return << 'EOT'};
  open my $file, '<', $item or die "$!\n";
  while (<$file>) {
     chomp;
     say;
  }
  close $file;
  say q{EOT};
  say "}";
}
