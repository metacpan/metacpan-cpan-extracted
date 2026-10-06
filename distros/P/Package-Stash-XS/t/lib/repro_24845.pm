use strict;
use warnings;
use Data::Dumper;
use Package::Stash;

# see https://github.com/Perl/perl5/issues/24845

my @tests = split("\n", ("cat\n" x 324));

for my $test (sort @tests) {
  my $stash = Package::Stash->new('Data::Dumper');
  my @l = $stash->list_all_symbols('CODE');
}

1;
