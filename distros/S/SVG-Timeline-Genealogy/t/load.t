use Test::More;

BEGIN {
  use_ok 'SVG::Timeline::Genealogy';
}

ok(my $tl = SVG::Timeline::Genealogy->new);
isa_ok($tl, 'SVG::Timeline::Genealogy');

done_testing;
