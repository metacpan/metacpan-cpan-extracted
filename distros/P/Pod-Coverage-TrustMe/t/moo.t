use strict;
use warnings;
use Test::Needs 'Moo';
use Test::More;
use Pod::Coverage::TrustMe;

unshift @INC, 't/corpus/moo';

for my $file (glob('t/corpus/moo/*.pm')) {
  $file =~ s{\At/corpus/moo/}{};
  my $package = $file;
  $package =~ s{\.pm\z}{};
  $package =~ s{/|\\}{::}g;

  my $cover = Pod::Coverage::TrustMe->new(
    package => $package,
    require_link => 1,
    ignore_imported => 0,
  );

  is $cover->coverage, 1, "$file is covered"
    or diag $cover->report;
}

done_testing;
