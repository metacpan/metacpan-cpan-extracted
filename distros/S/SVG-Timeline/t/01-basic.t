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

# A label that would overflow the IMAGE right edge should be right-justified,
# anchored to the event rectangle's right edge.
{
  my $tl2 = SVG::Timeline->new;

  # Narrow timeline: the long-label bar (2000-2001) overflows the image edge (2001).
  $tl2->add_event({
    start => 2000,
    end   => 2001,
    text  => 'A very long event label that would overflow the right edge of the image',
  });
  $tl2->add_event({
    start => 1990,
    end   => 2001,
    text  => 'Short',
  });

  my $xml         = $tl2->draw;
  my $long_event  = $tl2->events->[0];
  my $short_event = $tl2->events->[1];
  my $padding          = $tl2->bar_height * 0.2;
  my $expected_long_x  = ($long_event->end  * $tl2->units_per_year) - $padding;
  my $expected_short_x = ($short_event->start * $tl2->units_per_year) + $padding;

  like(
    $xml,
    qr/<text font-size="40" text-anchor="end" x="\Q$expected_long_x\E" y="90">A very long event label that would overflow the right edge of the image<\/text>/,
    'Long label near image right edge is right-justified to its event rectangle edge',
  );

  like(
    $xml,
    qr/<text font-size="40" text-anchor="start" x="\Q$expected_short_x\E" y="152.5">Short<\/text>/,
    'Short label keeps its default left alignment',
  );
}

# A label that is wider than its bar but does NOT overflow the image edge
# should remain left-aligned (text-anchor=start) at the bar left + padding.
{
  my $tl3 = SVG::Timeline->new;

  # Wide timeline 1990-2050; short bar at 1992-1993 with a brief label
  # that fits within the image but is wider than the 1-year bar.
  $tl3->add_event({
    start => 1992,
    end   => 1993,
    text  => 'Brief',
  });
  $tl3->add_event({
    start => 1990,
    end   => 2050,
    text  => 'Wide span',
  });

  my $xml       = $tl3->draw;
  my $short_bar = $tl3->events->[0];
  my $padding   = $tl3->bar_height * 0.2;
  my $expected_x = ($short_bar->start * $tl3->units_per_year) + $padding;

  like(
    $xml,
    qr/text-anchor="start" x="\Q$expected_x\E"[^>]*>Brief/,
    'Label wider than bar but not overflowing image stays left-aligned',
  );
}

done_testing();
