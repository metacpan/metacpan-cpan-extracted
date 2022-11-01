use strict;
use warnings;
use Test::More;

use SVG::Timeline;
use DateTime;

my $now = DateTime->now;

my $tl = SVG::Timeline->new;

$tl->add_event({
  start => '1987',
  end   => $now->strftime('%Y-%m-%d'),
  text  => 'Perl',
});

$tl->add_event({
  start => '2017-07-29',
  end   => $now->year,
  text  => 'SVG::Timeline on CPAN',
});

is($tl->count_events, 2, 'Correct number of events');
is($tl->events->[0]->index, 1, 'Correct index for event');
isa_ok($tl->svg, 'SVG');
my $vb1 = $tl->svg->getChildren->[0]{viewBox};

$tl->add_event({
  start => 1991,
  end   => $now->year,
  text  => 'Python',
});
is($tl->count_events, 3, 'Correct number of events');

my $vb2 = $tl->svg->getChildren->[0]{viewBox};
isnt($vb1, $vb2, 'Viewbox changed');

my $diag = $tl->draw;

ok($diag, 'Got a diagram');

done_testing();
