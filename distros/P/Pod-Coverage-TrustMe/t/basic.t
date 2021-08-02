use strict;
use warnings;
use Test::More;
use Pod::Coverage::TrustMe;

unshift @INC, 't/corpus';

for my $file (glob('t/corpus/*.pm')) {
  $file =~ s{\At/corpus/}{};
  my $package = $file;
  $package =~ s{\.pm\z}{};
  $package =~ s{/|\\}{::}g;

  my $cover = Pod::Coverage::TrustMe->new(package => $package, require_link => 1);

  is $cover->coverage, 1,
    "$file is covered";
}

done_testing;
