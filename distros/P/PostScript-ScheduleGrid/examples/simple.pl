#! /usr/bin/perl
#---------------------------------------------------------------------
# Simple example of PostScript::ScheduleGrid usage
#
# This example script is in the public domain.
# Copy from it as you like.
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.010;

use DateTime;
use PostScript::ScheduleGrid;

sub dt # Trivial parser to create DateTime objects
{
  my %dt = qw(time_zone local);
  @dt{qw( year month day hour minute )} = split /\D+/, $_[0];
  while (my ($k, $v) = each %dt) { delete $dt{$k} unless defined $v }
  DateTime->new(\%dt);
} # end dt

my $grid = PostScript::ScheduleGrid->new(
  start_date => dt('2011-10-02 18'),
  end_date   => dt('2011-10-02 22'),
  resource_title => 'Channel',
  time_headers => ['h:mm a', 'h:mm a'],
  categories => { GR => [qw(Stripe direction right)],
                  GL => 'Stripe',
                  G => 'Solid' },
  resources => [
    { name => '2 FOO',
      lines => 1,
      schedule => [
        [ dt('2011-10-02 18'), dt('2011-10-02 19'), 'Some hour-long show', 'G' ],
        [ dt('2011-10-02 19'), dt('2011-10-02 20'), 'Another hour-long show' ],
        [ dt('2011-10-02 20'), dt('2011-10-02 20:30'), 'Half-hour show', 'GR' ],
        [ dt('2011-10-02 21'), dt('2011-10-02 22'), 'Show order insignificant' ],
        [ dt('2011-10-02 20:30'), dt('2011-10-02 21'), 'Second half-hour', 'GR' ],
      ],
    }, # end channel 2 FOO
    { name => '1 Channel',
      schedule => [
        [ dt('2011-10-02 18'), dt('2011-10-02 22'),
          'Unlike events, the order of resources is significant.', 'GL' ],
      ],
    }, # end channel 1 Channel
    { name => '4 Channel',
      lines => 4,
      schedule => [
        [ dt('2011-10-02 18'), dt('2011-10-02 19'),
          'Unlike events, the order of resources is significant. This is a long text.' ],
      ],
    }, # end channel 1 Channel
  ],
);

say 'Writing simple.ps...';
$grid->output('simple.ps');
