#!/usr/bin/env perl
use lib './lib';
use Proc::Forkmap;

pipe(my $reader, my $writer);
select((select($writer), $|=1)[0]);  # autoflush
 
sub foo {
  close $reader;
  my $n = shift;
  sleep $n;
  print $writer "slept $n seconds\n";
}

my @x = (1, 4, 2);

forkmap { foo($_) } @x;

close $writer;
while (<$reader>) {
  print $_;
}
close $reader;
