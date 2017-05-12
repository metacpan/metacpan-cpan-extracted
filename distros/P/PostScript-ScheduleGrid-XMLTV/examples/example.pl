#! /usr/bin/perl
#---------------------------------------------------------------------
# Example usage of PostScript::ScheduleGrid::XMLTV
# by Christopher J. Madsen
#
# This example script is in the public domain.
# Copy from it as you like.
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.010;

use DateTime ();
use PostScript::ScheduleGrid::XMLTV ();

my $dataFile = $ARGV[0] // 'data.xml';
my $outFile  = $ARGV[1] // 'listings.ps';

die "You must provide an XMLTV data file\n" unless -f $dataFile;

# Produce 3 days of listings starting tomorrow at 6am
my $start_date = DateTime->today(time_zone => 'local')
                         ->add(days => 1, hours => 6);
my $end_date = $start_date->clone->add(days => 3);

#---------------------------------------------------------------------
# Customize listings through program_callback:

my %favoriteShow = map { $_ => 1 } (
  'Castle',
  'MythBusters',
  'Person of Interest',
);

sub callback
{
  my ($p) = shift;

  $p->{category} = 'sports'
      if $p->{dd_progid} =~ /^SP/ or
          ($p->{xml}{category} and
           grep { $_->[0] =~ /^Sports.+(?:event|talk)$/ }
                @{$p->{xml}{category}});

  $p->{category} = 'fav' if $favoriteShow{$p->{show}}
      or ($p->{parser}->get_text($p->{xml}{desc}) // '') =~ /Caviezel/;
  # example of searching the description for specified text
} # end callback

#---------------------------------------------------------------------
my $tv = PostScript::ScheduleGrid::XMLTV->new(
  program_callback => \&callback,
  start_date       => $start_date,
  end_date         => $end_date,
  channel_settings => {
    '285 EWTN'               => { lines => 3 },
    'I16374.labs.zap2it.com' => { lines => 1 },
  },
);

$tv->parsefiles($dataFile);

#---------------------------------------------------------------------
say "Preparing grid";

my $grid = $tv->grid(
  categories => { fav    => 'Solid',
                  sports => [qw(Stripe  direction right)] },
  landscape  => 1,
  grid_hours => 6,
  (map { $_ => 18 } qw(left_margin right_margin top_margin bottom_margin)),
  cell_font_size => 8,
  line_height    => 11,
);

$grid->output($outFile);

# Local Variables:
# compile-command: "perl example.pl data.xml /tmp/listings.ps"
# End:
