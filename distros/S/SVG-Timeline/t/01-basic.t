use strict;
use warnings;
use Test::More;

use SVG::Timeline;
use Time::Piece;

my $tl = SVG::Timeline->new;

$tl->add_event({
  start => 1987,
  end   => localtime->year,
  text  => 'Perl',
});

is($tl->count_events, 1, 'Correct number of events');
is($tl->events->[0]->index, 1, 'Correct index for event');
isa_ok($tl->svg, 'SVG');
my $vb1 = $tl->svg->getChildren->[0]{viewBox};

$tl->add_event({
  start => 1991,
  end   => localtime->year,
  text  => 'Python',
});
is($tl->count_events, 2, 'Correct number of events');

my $vb2 = $tl->svg->getChildren->[0]{viewBox};
isnt($vb1, $vb2, 'Viewbox changed');

my $diag = $tl->draw;

ok($diag, 'Got a diagram');

done_testing();
