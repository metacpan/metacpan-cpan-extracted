use strictures 1;
use Test::More qw(no_plan);
use IO::All;

foreach my $file (io('lib')->all_files(0)) {
  (my $name = $file->name) =~ s/^lib\///;
  ok(eval { require $name; 1 }, "${file} loaded ok");
  warn $@ if $@;
}
