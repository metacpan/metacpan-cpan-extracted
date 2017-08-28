
use Test::More;

use SVG::Timeline::Genealogy;
use Time::Piece;

my $tl = SVG::Timeline::Genealogy->new;

$tl->add_person({
  ahnen => 1,
  start => 1987,
  end   => localtime->year,
  text  => 'Perl',
});

is($tl->count_events, 1, 'Correct number of events');
isa_ok($tl->svg, 'SVG');

my $diag = $tl->draw;

ok($diag, 'Got a diagram');

done_testing();
