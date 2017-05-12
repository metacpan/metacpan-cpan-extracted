#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2015 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 15 Aug 2015
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test using sample XMLTV data in sample.xml
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use Test::More 0.88 tests => 3; # done_testing

use FindBin '$RealBin';

use DateTime::Format::XMLTV ();
use PostScript::ScheduleGrid::XMLTV ();

#---------------------------------------------------------------------
# Customize listings through program_callback:

my %favoriteShow = map { $_ => 1 } (
  'Jeopardy!',
  'Mystery!',
);

sub callback
{
  my ($p) = shift;

  $p->{category} = 'sports'
      if $p->{dd_progid} =~ /^SP/ or
          ($p->{xml}{category} and
           grep { $_->[0] =~ /^Sports.+(?:event|talk)$/ }
                @{$p->{xml}{category}});

  $p->{category} = 'fav' if $favoriteShow{$p->{show}};
  # example of searching the description for specified text
} # end callback

#---------------------------------------------------------------------
# Construct a PostScript::ScheduleGrid::XMLTV from sample.xml

my $start_date = DateTime::Format::XMLTV->parse_datetime('200807150600');
my $end_date = $start_date->clone->add(hours => 6);

my $tv = PostScript::ScheduleGrid::XMLTV->new(
  program_callback => \&callback,
  start_date       => $start_date,
  end_date         => $end_date,
  channel_settings => {
    '11 KTVT'                => { lines => 3 },
    'I10179.labs.zap2it.com' => { lines => 1 },
  },
);

isa_ok($tv, 'PostScript::ScheduleGrid::XMLTV', '$tv');

$tv->parsefiles("$RealBin/sample.xml");

#---------------------------------------------------------------------
# To test that the channels attribute was created correctly,
# we clone it and convert DateTime objects to strings.

my $channels = $tv->channels;
my %copy;

while (my ($channel_id, $data) = each %$channels) {
  $copy{$channel_id} = {
    # Copy everything from $data
    %$data,
    # except for 'schedule', which we need to modify
    schedule => [
      map {
        my @event = @$_;
        for my $dt (@event[0,1]) {
          $dt = $dt->format_cldr('yyyy-MM-dd HH:mm');
        }
        \@event;
      } sort {
        DateTime->compare_ignore_floating($a->[0], $b->[0])
      } @{ $data->{schedule} }
    ],
  };
}

# Did we parse the file correctly?

is_deeply(
  \%copy,
  {
    "I10179.labs.zap2it.com" => {
      Id => "I10179.labs.zap2it.com",
      lines => 1,
      name => "34 ESPN",
      Number => 34,
      schedule => [
        [
          "2008-07-15 09:00", "2008-07-15 12:30",
          "Baseball: Los Angeles Angels of Anaheim at Kansas City Royals",
          "sports",
        ],
      ],
    },
    "I10436.labs.zap2it.com" => {
      Id => "I10436.labs.zap2it.com",
      lines => 2,
      name => "13 KERA",
      Number => 13,
      schedule => [
        ["2008-07-15 06:30", "2008-07-15 07:00", "NOW on PBS"],
        [
          "2008-07-15 07:00", "2008-07-15 08:30",
          "Mystery!: Foyle's War, Series IV: Bleak Midwinter",
          "fav",
        ],
        [
          "2008-07-15 08:30", "2008-07-15 10:00",
          "Mystery!: Foyle's War, Series IV: Casualties of War",
          "fav",
        ],
        ["2008-07-15 10:00", "2008-07-15 10:30", "BBC World News"],
        ["2008-07-15 10:30", "2008-07-15 11:00", "Sit and Be Fit"],
      ],
    },
    "I10759.labs.zap2it.com" => {
      Id => "I10759.labs.zap2it.com",
      lines => 3,
      name => "11 KTVT",
      Number => 11,
      schedule => [
        ["2008-07-15 06:00", "2008-07-15 08:00", "The Early Show"],
        ["2008-07-15 08:00", "2008-07-15 09:00", "Rachael Ray"],
        ["2008-07-15 09:00", "2008-07-15 10:00", "The Price Is Right"],
        ["2008-07-15 10:00", "2008-07-15 10:30", "Jeopardy!", "fav"],
        [
          "2008-07-15 10:30", "2008-07-15 11:30",
          "The Young and the Restless: Sabrina Offers Victoria a Truce",
        ],
      ],
    },
  },
  'TV schedules parsed correctly'
);

#---------------------------------------------------------------------
# Can we get a PostScript::ScheduleGrid from it?

my $grid = $tv->grid(
  time_zone => $start_date->time_zone,
  categories => { fav    => 'Solid',
                  sports => [qw(Stripe  direction right)] },
  landscape  => 1,
  grid_hours => 6,
  (map { $_ => 18 } qw(left_margin right_margin top_margin bottom_margin)),
  cell_font_size => 8,
  line_height    => 11,
);

isa_ok($grid, 'PostScript::ScheduleGrid', '$grid');

# # For debugging, you can output the grid:
# $grid->output('/tmp/grid.ps');

done_testing;
