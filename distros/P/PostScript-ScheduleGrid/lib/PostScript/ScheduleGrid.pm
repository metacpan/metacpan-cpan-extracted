#---------------------------------------------------------------------
package PostScript::ScheduleGrid;
#
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 28 Dec 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Print a schedule in a grid format
#---------------------------------------------------------------------

our $VERSION = '0.05';
# This file is part of PostScript-ScheduleGrid 0.05 (August 22, 2015)

use 5.010;
use Moose;

use MooseX::Types::Moose qw(ArrayRef Bool HashRef Int Num Str);
use MooseX::Types::DateTime (); # Just load coercions
use PostScript::ScheduleGrid::Types ':all';

use DateTime ();
use DateTime::TimeZone ();
use List::Util 1.20 qw(max min); # support overloaded comparisons
use Module::Runtime qw( require_module );
use POSIX qw(floor);
use PostScript::File 2.20 qw(str); # Need use_functions

use namespace::autoclean -also => qr/^i[[:upper:]]/;

sub iStart () { 0 }
sub iEnd   () { 1 }
sub iName  () { 2 }
sub iCat   () { 3 }

#=====================================================================


has cell_font => (
  is      => 'ro',
  isa     => Str,
  default => 'Helvetica',
);

has cell_font_size => (
  is      => 'ro',
  isa     => Dimension,
  coerce  => 1,
  default => 7,
);

has _metrics => (
  is       => 'ro',
  isa      => FontMetrics,
  init_arg => undef,
  lazy     => 1,
  default  => sub {
    my $s = shift;
    $s->ps->get_metrics($s->cell_font . '-iso', $s->cell_font_size);
  },
);


has extra_height => (
  is      => 'ro',
  isa     => Dimension,
  coerce  => 1,
  lazy    => 1,
  default => sub { shift->cell_font_size },
);


has heading_format => (
  is      => 'ro',
  isa     => Str,
  default => 'EEEE, MMMM d, y',
);

has heading_font => (
  is      => 'ro',
  isa     => Str,
  default => 'Helvetica-Bold',
);

has heading_font_size => (
  is      => 'ro',
  isa     => Dimension,
  coerce  => 1,
  default => 12,
);

has time_headers => (
  is      => 'ro',
  isa     => TimeHeaders,
  default => sub { ['h a', 'h:mm'] }
);

has title_font => (
  is      => 'ro',
  isa     => Str,
  default => 'Helvetica-Bold',
);

has title_font_size => (
  is      => 'ro',
  isa     => Dimension,
  coerce  => 1,
  default => 9,
);


has grid_hours => (
  is      => 'ro',
  isa     => Int,
  lazy    => 1,
  default => sub { shift->landscape ? 6 : 4 },
);


has title_width => (
  is      => 'ro',
  isa     => Dimension,
  coerce  => 1,
  lazy    => 1,
  builder => '_compute_title_width',
);


has five_min_width => (
  is      => 'ro',
  isa     => Dimension,
  coerce  => 1,
  lazy    => 1,
  builder => '_compute_five_min_width',
);

has half_width => (
  is       => 'ro',
  isa      => Dimension,
  coerce   => 1,
  lazy     => 1,
  init_arg => undef,
  default  => sub { shift->five_min_width * 6 },
);

has hour_width => (
  is       => 'ro',
  isa      => Dimension,
  coerce   => 1,
  lazy     => 1,
  init_arg => undef,
  default  => sub { shift->five_min_width * 12 },
);


has resource_title => (
  is       => 'ro',
  isa      => Str,
);


has resources => (
  is       => 'ro',
  isa      => ArrayRef[HashRef],
  required => 1,
);

has grid_height => (
  is       => 'ro',
  isa      => Dimension,
  coerce   => 1,
  lazy     => 1,
  init_arg => undef,
  default  => sub { my $s = shift; my $c = $s->resources; my $extra = 0;
    $extra += $_->{lines} - 1 for @$c;
    (2 + scalar @$c) * $s->line_height +
    $extra * $s->extra_height;
  },
);

has grid_width => (
  is       => 'ro',
  isa      => Dimension,
  coerce   => 1,
  lazy     => 1,
  init_arg => undef,
  default  => sub { my $s = shift;
    $s->title_width + $s->five_min_width * 12 * $s->grid_hours
  },
);


has cell_bot => (
  is      => 'ro',
  isa     => Dimension,
  coerce  => 1,
  default => 2.5,
);

has cell_left => (
  is      => 'ro',
  isa     => Dimension,
  coerce  => 1,
  default => 1.4,
);

has line_height => (
  is      => 'ro',
  isa     => Dimension,
  coerce  => 1,
  default => 10,
);

has heading_baseline => (
  is      => 'ro',
  isa     => Dimension,
  coerce  => 1,
  default => 3,
);


has start_date => (
  is       => 'ro',
  isa      => 'DateTime',
  required => 1,
);

has end_date => (
  is       => 'ro',
  isa      => 'DateTime',
  required => 1,
);

has time_zone => (
  is       => 'ro',
  isa      => 'DateTime::TimeZone',
  coerce   => 1,
  default  => 'local',
);

has _cur_date => (
  is       => 'rw',
  isa      => 'DateTime',
);


has title_baseline => (
  is      => 'ro',
  isa     => Dimension,
  coerce  => 1,
  default => 1.6875,
);

#=====================================================================


has ps_parameters => (
  is       => 'ro',
  isa      => HashRef,
  default  => sub { {} },
);


has paper_size => (
  is      => 'ro',
  isa     => Str,
  default => 'Letter',
);


has top_margin => (
  is      => 'ro',
  isa     => Int,
  default => 36,
);

has bottom_margin => (
  is      => 'ro',
  isa     => Int,
  default => 36,
);

has left_margin => (
  is      => 'ro',
  isa     => Int,
  default => 22,
);

has right_margin => (
  is      => 'ro',
  isa     => Int,
  default => 22,
);


has landscape => (
  is      => 'ro',
  isa     => Bool,
  default => 0,
);


has ps => (
  is         => 'ro',
  isa        => 'PostScript::File',
  lazy_build => 1,
  handles    => ['output'],
);

*get__PostScript_File = \&ps;   # Alias for PostScript::Convert

sub _build_ps
{
  my ($self) = @_;

  PostScript::File->new(
    paper       => $self->paper_size,
    top         => $self->top_margin,
    bottom      => $self->bottom_margin,
    left        => $self->left_margin,
    right       => $self->right_margin,
    title       => 'TV Grid',
    order       => 'Ascend',
    reencode    => 'cp1252',
    file_ext    => '',
    font_suffix => '-iso',
    landscape   => $self->landscape,
    newpage     => 0,
    %{ $self->ps_parameters },
  );
} # end _build_ps

has _category => (
  is         => 'ro',
  isa        => HashRef,
  init_arg   => undef,
  default    => sub { { '' => '' } },
);

has _styles => (
  is         => 'ro',
  isa        => ArrayRef[Style],
  init_arg   => undef,
  default    => sub { [] },
);

#---------------------------------------------------------------------
sub _compute_title_width
{
  my $self = shift;

  my $metrics = $self->ps->get_metrics($self->title_font . '-iso',
                                       $self->title_font_size);

  my $width = max( map { $metrics->width($_->{name}) } @{ $self->resources });

  $width + 2 * $self->cell_left; # Add some padding
} # end _compute_title_width

#---------------------------------------------------------------------
sub _compute_five_min_width
{
  my $self = shift;

  floor(8 * ($self->ps->get_printable_width - $self->title_width) /
        (3 * $self->grid_hours)) * (1/32);
} # end _compute_five_min_width

#---------------------------------------------------------------------
sub BUILD
{
  my ($self, $args) = @_;

  if (my $cats = $args->{categories}) {
    my $category = $self->_category;
    my $styles   = $self->_styles;
    my $id = 'A';

    my %used;

    foreach my $cat (sort keys %$cats) {
      confess 'Category name cannot be empty' unless length $cat;


      my $def = $cats->{$cat};
      my ($class, @args);

      if (not ref $def) {
        $class = $def;
      } else {
        ($class, @args) = @$def;
      }

      my $cacheKey = join("\0", $class, @args);

      if (defined $used{$cacheKey}) {
        # We've already defined an equivalent style
        $category->{$cat} = $used{$cacheKey};
      } else {
        my $name = 'S' . $id++;
        $category->{$cat} = $used{$cacheKey} = $name;

        $class = "PostScript::ScheduleGrid::Style::$class"
            unless $class =~ s/^=//;

        require_module($class);

        confess("$class does not do PostScript::ScheduleGrid::Role::Style")
            unless $class->DOES('PostScript::ScheduleGrid::Role::Style');


        push @$styles, $class->new(@args, name => $name);
      }
    } # end foreach $cat in %$cats
  } # end if categories

  $self->_run;
} # end BUILD

#---------------------------------------------------------------------
sub _ps_functions
{
  my $self = shift;

  my $functions = <<'END PS INIT';
/pixel {72 mul 300 div} def % 300 dpi only

/C                             % HEIGHT WIDTH LEFT VPOS C
{
  gsave
  newpath moveto                % HEIGHT WIDTH
  dup 0 rlineto                 % HEIGHT WIDTH
  0 3 -1 roll rlineto           % WIDTH
  -1 mul 0 rlineto
  closepath clip
} def

/R {grestore} def

/H                             % YPOS H
{
  newpath
  0 exch moveto
  $grid_width 0 rlineto
  stroke
} def

/P1 {1 pixel setlinewidth} def
/P2 {2 pixel setlinewidth} def

/S                             % STRING X Y S
{
 newpath moveto show
} def

/V                             % XPOS YPOS HEIGHT V
{
  newpath
  3 1 roll
  moveto
  0 exch rlineto
  stroke
} def

%---------------------------------------------------------------------
% Print the date, times, resource names, & exterior grid:
%
% HEADER TIME1 TIME2 ... TIME12
%
% Enter with CellFont selected
% Leaves the linewidth set to 2 pixels

/prg
{
  ResourceTitle $cell_left %{$grid_height - $line_height + $cell_bot} S
  ResourceTitle $cell_left $cell_bot S

  TitleFont setfont
  %{$title_width + $hour_width * $grid_hours - $half_width/2}
  -$half_width $title_width
  % stack (TIME XPOS)
  {
    dup %{$grid_height - $line_height + $title_baseline} 3 index showCenter
    $title_baseline 3 -1 roll showCenter
  } for

END PS INIT

  my @hlines;
  my $resources      = $self->resources;
  my $ps             = $self->ps;
  my $cell_left      = $self->cell_left;
  my $line_height    = $self->line_height;
  my $title_baseline = $self->title_baseline;
  my $extra_height   = $self->extra_height;
  my $vpos = $self->grid_height - $line_height;
  $functions .= '  ';
  foreach my $c (@$resources) {
      push @hlines, $vpos;
      my $ex = ($c->{lines} - 1) * $extra_height;
      $vpos -= $line_height + $ex;
      $c->{vpos} = $vpos;
      $functions .= $ps->pstr($c->{name}) . ($vpos+$title_baseline+$ex/2);
  }
  $functions .= "\n  " . @$resources . " {$cell_left exch S} repeat\n\n";
  push @hlines, $line_height;

  $functions .= <<'EOT';
  HeadFont setfont
  $title_width %{$grid_height + $heading_baseline} S

  P1
  newpath
  0 0 moveto
  $grid_width 0 rlineto
  $grid_width $grid_height lineto
  0 $grid_height lineto
  closepath stroke

  %{$title_width + $half_width} $hour_width %{$grid_width - $five_min_width}
  {dup %{$grid_height-$line_height} $line_height V 0 $line_height V} for
EOT

    $functions .=  '  '.join(' ',@hlines)."\n  ".scalar @hlines;
    $functions .= <<'EOT';
 {H} repeat

  P2
  %{$title_width + $hour_width} $hour_width %{$grid_width-1}
  {dup %{$grid_height-$line_height} $line_height V 0 $line_height V} for
  $title_width 0 $grid_height V
} def
EOT

  $self->_ps_eval(\$functions);

  foreach my $style (@{ $self->_styles }) {
    $functions .= $style->define_style($self);
  }

  # Append time, because this should not be substituted for any other version:
  return (sprintf('PostScript_ScheduleGrid_%s_%s', $$, time), $functions, $VERSION);
} # end _ps_functions

#---------------------------------------------------------------------
# Substitute values into a string:
#
# Passed a list of string references.  Each string modified in-place.
# "$method" is replaced with the value of $self->method.
# "%{...}" is replaced with the result of evaluating ...

sub _ps_eval
{
  my $self = shift;

  foreach my $psRef (@_) {
    $$psRef =~ s/\$([a-z0-9_]+)/ str($self->$1) /ieg;
    $$psRef =~ s[%\{([^\}]+)\}][$1]eeg;
  }
} # end _ps_eval

#---------------------------------------------------------------------
# Clean up the list of resource data:
#
# Missing parameters are set to their default value.
# Any floating times in the schedule are converted to the grid's time zone.
# The schedule is sorted by start time.

sub _normalize_resources
{
  my $self = shift;

  my $resources = $self->resources;
  my $tz        = $self->time_zone;
  my $cat       = $self->_category;

  for my $c (@$resources) {
    confess "All resources must have a name" unless defined $c->{name};

    $c->{lines} ||= 1;
    confess sprintf("%s is not a supported value for 'lines' in resource %s",
                    $c->{lines}, $c->{name})
        unless $c->{lines} == int($c->{lines}) and $c->{lines} > 0;

    my $schedule = $c->{schedule};

    # Convert any floating times to specified time zone:
    for my $rec (@$schedule) {
      confess sprintf("Invalid category '%s' in %s event at %s",
                      $rec->[iCat], $c->{name}, $rec->[iStart])
          unless exists $cat->{$rec->[iCat] // ''};
      for my $date (@$rec[iStart, iEnd]) {
        $date->set_time_zone($tz) if $date->time_zone->is_floating;
      }
    } # end for $rec in @$schedule

    # Make sure the schedule is sorted:
    @$schedule = sort {
      DateTime->compare_ignore_floating($a->[iStart], $b->[iStart])
    } @$schedule;
  } # end for $c in @$resources
} # end _normalize_resources


#---------------------------------------------------------------------
sub _run
{
  my $self = shift;

  $self->_normalize_resources;

  # Initialise PostScript::File object:
  my $ps = $self->ps;

  $ps->need_resource(font => $self->cell_font, $self->heading_font,
                     $self->title_font);

  $ps->use_functions(qw(setColor showCenter));
  $ps->add_procset($self->_ps_functions);

  { my $setup = <<'END SETUP';
/CellFont   /$cell_font-iso    findfont  $cell_font_size    scalefont  def
/HeadFont   /$heading_font-iso findfont  $heading_font_size scalefont  def
/TitleFont  /$title_font-iso   findfont  $title_font_size   scalefont  def
END SETUP
    $self->_ps_eval(\$setup);

    $setup .= sprintf("/ResourceTitle %s def\n",
                      $ps->pstr($self->resource_title // ''));
    $ps->add_setup($setup);
  }

  my $cat          = $self->_category;
  my $resources    = $self->resources;
  my $grid_height  = $self->grid_height;
  my $line_height  = $self->line_height;
  my $extra_height = $self->extra_height;
  my $start        = $self->start_date;
  my $stop_date    = $self->end_date;
  my $left_mar     = $self->left_margin;

  # Make sure start_date & end_date are in the specified time zone:
  {
    my $tz = $self->time_zone;
    $start->set_time_zone($tz);
    $stop_date->set_time_zone($tz);
  }

  $self->_cur_date( $start );

  # Decide if we have room for multiple grids on a page:
  my @grid_offsets;
  {
    my $bottom_margin = $self->bottom_margin;
    my $top_margin    = $self->top_margin;

    my $total_height = ($grid_height + $self->heading_baseline +
                        $self->heading_font_size);
    my @bb = $ps->get_bounding_box;

    push @grid_offsets, $bb[3] - $total_height;

    my $page_height = $bb[3] - $bb[1];

    my $grids = floor($page_height / $total_height);
    if ($grids > 1) {
      my $spacing = to_Dimension(
        $total_height + ($page_height - $grids * $total_height) / ($grids-1)
      );
      push @grid_offsets, (-$spacing) x ($grids-1);
    } # end if multiple grids
  } # end block for computing @grid_offsets

  # Loop for each page:
 PAGE:
  while (1) {
    $ps->newpage;
    $ps->add_to_page("$left_mar 0 translate\n");

    foreach my $grid_offset (@grid_offsets) {
      my $end = $start->clone->add(hours => $self->grid_hours);

      my $vpos = $grid_height - $line_height;

      $ps->add_to_page("0 $grid_offset translate\n" .
                       "CellFont setfont\n0 setlinecap\n");

      for my $resource (@$resources) {
        my $lines = $resource->{lines};
        $vpos = $resource->{vpos};
        my $height = $line_height + ($lines-1) * $extra_height;

        my $schedule = $resource->{schedule};

        shift @$schedule while @$schedule and $schedule->[0][iEnd] < $start;

        while (@$schedule and $schedule->[0][iStart] < $end) {
          my $s = shift @$schedule;

          my $left = $self->_add_vline(max($s->[iStart], $start), $height,$vpos);
          my $right = $self->_add_vline(min($s->[iEnd], $end), $height,$vpos);
          $ps->add_to_page(sprintf "%s %s %s %s C\n%s",
                           $height, $right - $left, $left, $vpos,
                           defined $s->[iCat] ? "$cat->{$s->[iCat]}\n" : '');
          $self->_add_cell_text($left,$right,$vpos,$lines,$s->[iName]);
          $ps->add_to_page("R\n");
          if ($s->[iEnd] > $end) {
            unshift @$schedule, $s;
            last;
          }
        } # end while @$schedule
      } # end for @$resources

      $self->_end_grid_page;
      $self->_cur_date($start = $end);

      last PAGE unless $start < $stop_date;
    } # end foreach grid
  } # end PAGE loop
} # end _run

has _vlines => (
  is       => 'ro',
  isa      => ArrayRef[HashRef],
  init_arg => undef,
  default  => sub { [ {}, {} ] },
);

sub _add_vline
{
  my ($self,$time,$height,$vpos) = @_;

  my $minutes = $time->subtract_datetime($self->_cur_date)->in_units('minutes');

#  printf "  %s - %s = %s\n", $self->_cur_date, $time, $minutes;

  my $title_width = $self->title_width;

  my $hash = $self->_vlines->[ $minutes % 60 == 0 ];
  $hash->{$height} = [] unless $hash->{$height};
  my $list = $hash->{$height};
  my $hpos = ($title_width + int(($minutes + 3) / 5) * $self->five_min_width);

  my $entry = "$hpos $vpos";
  push @$list, $entry
      unless $hpos == $title_width or $hpos == $self->grid_width or
             (@$list and $list->[-1] eq $entry);
  $hpos;
} # end _add_vline

sub _end_grid_page
{
  my $self = shift;

  my $vpos = $self->grid_height - $self->line_height;
  my $time = $self->_cur_date->clone;
  my $ps   = $self->ps;
  my $headers = $self->time_headers;

  my $code = $ps->pstr($time->format_cldr($self->heading_format));
  for (0 .. (2 * $self->grid_hours - 1)) {
    $code .= $ps->pstr($time->format_cldr( $headers->[ $_ % 2 ]));
    $time->add(minutes => 30);
  }

  $code .= "prg\n";
  $code .= $self->_print_vlines(1);
  $code .= "P1\n";
  $code .= $self->_print_vlines(0);

  $ps->add_to_page($code);
} # end _end_grid_page

sub _print_vlines
{
  my ($self,$vlines) = @_;

  $vlines = $self->_vlines->[$vlines];
  my $code = '';
  while (my ($height, $list) = each %$vlines) {
      $code .= join(' ',@$list)."\n".scalar @$list." {$height V} repeat\n";
  }
  %$vlines = ();

  return $code;
} # end _print_vlines

#---------------------------------------------------------------------
sub _add_cell_text
{
    my ($self, $left, $right, $vpos, $lines, $show) = @_;

    my $extra_height = $self->extra_height;

    $left += $self->cell_left;
    $vpos += $self->cell_bot + $extra_height * ($lines-1);
    my $width = $right - $left;

    my $metrics = $self->_metrics;

    my @chars;

  BREAKDOWN: {
      my @warnings;
      my @lines = $metrics->wrap($width, $show,
                                 { maxlines => $lines, quiet => 1,
                                   warnings => \@warnings, @chars });

      redo BREAKDOWN if @warnings
          and $show =~ s/^(?:The|New|An?|(?:Real )?Adventures of) +//i;

      if (($lines[-1] =~ s/[ \t]*\n.*//s or @warnings) and not @chars) {
        @chars = (chars => ".,:?)]-/\xAD\x{2013}\x{2014}");
        redo BREAKDOWN;   # Try again with more permissive line breaks
      }

      my $ps = $self->ps;
      my $code = '';

      for my $line (@lines) {
        $code .= sprintf("%s %s %s S\n", $ps->pstr($line),
                         $left, $vpos) if length $line;
        $vpos -= $extra_height;
      }
      $ps->add_to_page($code);
    } # end BREAKDOWN
} # end _add_cell_text

#=====================================================================
# Package Return Value:

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

PostScript::ScheduleGrid - Print a schedule in a grid format

=head1 VERSION

This document describes version 0.05 of
PostScript::ScheduleGrid, released August 22, 2015
as part of PostScript-ScheduleGrid version 0.05.

=head1 SYNOPSIS

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
    categories => {
      G  => 'Solid',
      GR => [qw( Stripe direction right )],
    },
    resource_title => 'Channel',
    resources => [
      { name => '2 FOO',
        schedule => [
          [ dt('2011-10-02 18'), dt('2011-10-02 19'), 'Some hour-long show', 'G' ],
          [ dt('2011-10-02 19'), dt('2011-10-02 20'), 'Another hour-long show' ],
          [ dt('2011-10-02 20'), dt('2011-10-02 20:30'), 'Half-hour show', 'GR' ],
          [ dt('2011-10-02 21'), dt('2011-10-02 22'), 'Show order insignificant' ],
          [ dt('2011-10-02 20:30'), dt('2011-10-02 21'), 'Second half-hour' ],
        ],
      }, # end resource 2 FOO
      { name => '1 Channel',
        schedule => [
          [ dt('2011-10-02 18'), dt('2011-10-02 22'),
            'Unlike events, the order of resources is significant.' ],
        ],
      }, # end resource 1 Channel
    ],
  );

  $grid->output('/tmp/testgrid.ps');

=head1 DESCRIPTION

PostScript::ScheduleGrid generates a printable schedule in a grid
format commonly used for TV listings.  (If you are considering using
it for actual TV listings, you should look at
L<PostScript::ScheduleGrid::XMLTV>, which creates a
PostScript::ScheduleGrid from TV listings data gathered by
L<XMLTV>. L<http://xmltv.org>)

A schedule is comprised of resources in which events take place at
specified times.  For a television schedule, each TV channel is a
resource, and each show is an event.  For a conference, each meeting
room is a resource, and each talk is an event.

The printed grid has a row for each resource, with times as columns.
The position and size of an event indicates the time it begins and
ends, as well as which resource it's associated with.  It's not
possible for an event to be associated with more than one resource.
If you need that, you can simulate it by assigning similar events to
each resource.

If you want to save the schedule as a PDF, you can pass a ScheduleGrid
object to L<PostScript::Convert/psconvert> (instead of calling the
C<output> method).

=head1 ATTRIBUTES


=head2 Grid Data

These attributes supply the data that will appear in the grid.


=head3 end_date

This is the date and time at which the listings will end.  Required.


=head3 resource_title

This is the header that will be displayed (in the L<cell_font>) at the
top and bottom of the column of resource names.  The default is to
have no header.  (For TV listings, you might set this to C<Channel>.)


=head3 resources

This is an arrayref of resource information.  Resources are listed in
the order they appear.  Each resource is represented by a hashref with
the following keys:

=over

=item name

The resource name as it should appear in the grid.

=item lines

The number of lines that should be used for event listings (default 1).

=item schedule

An arrayref of events associated with this resource.  Each event is
represented by a 4-element arrayref: S<C<[START, STOP, NAME, CATEGORY]>>.

C<START> and C<STOP> are the start and stop times (as DateTime
objects).  C<NAME> is the name of the event as it should appear in
the grid.  The optional C<CATEGORY> causes the event to be displayed
specially.  If present, it must be one of the keys in the
C<categories> attribute.

The arrayref will be modified during the grid processing.  Events
may be listed in any order; the arrayref will be sorted automatically.

=back

All other keys are reserved.  Any key beginning with an uppercase letter is
reserved for use by programs using PostScript::ScheduleGrid (and will be
ignored by this module).

As an example, in a grid displaying TV listings, each channel would be
a resource, and each program airing on that channel would be an event.


=head3 start_date

This is the date and time at which the listings will begin.  Required.


=head3 time_zone

The time zone that the listings are in.  Any floating times will be
converted to this time zone.  Defaults to your local time zone.


=head2 Grid Formatting

These attributes affect the PostScript::File object, or control the
formatting of the grid.  All dimensions are in points.


=head3 bottom_margin

This is the bottom margin (default 36, or 1/2 inch).


=head3 categories

This is not a normal attribute; you may supply a value to the
constructor, but it cannot be accessed afterwards.  It is a hashref
keyed by category name.  Category names are arbitrary strings.  Each
event may be assigned to one category.

The value associated with the category name defines the style that
will be applied to events in this category. It is either a string (a
class name), or an arrayref of class name and parameters:
S<C<[ CLASS, KEY1, VALUE1, KEY2, VALUE2, ... ]>>.

The class name is prefixed with C<PostScript::ScheduleGrid::Style::>
unless it begins with C<=> (which is removed).  The class must do the
L<Style|PostScript::ScheduleGrid::Role::Style> role.

The standard styles are
L<Solid|PostScript::ScheduleGrid::Style::Solid> (for a solid
background) and L<Stripe|PostScript::ScheduleGrid::Style::Stripe> (for
a diagonally striped background).

Note: If you list the same style class (with the same parameters) more
than once, only one copy of that style will be created.


=head3 cell_bot

This is the space between the bottom of a cell and the baseline of the
text inside it (default 2.5).


=head3 cell_font

This is the name of the font used for event titles in the grid
(default C<Helvetica>).


=head3 cell_font_size

This is the size of the font used for event titles in the grid (default 7).


=head3 cell_left

This is the space between the left of a cell and the beginning of the
text inside it (default 1.4).


=head3 extra_height

This is the height added to C<line_height> for a row with multiple
lines.  The height of a row is (S<C<line_height + (lines-1) * extra_height>>).
Defaults to C<cell_font_size>.


=head3 five_min_width

This is the width of five minutes in the grid (all durations are
rounded to the nearest five minutes).  You should probably keep the
default value, which is calculated based on the page margins and the
C<title_width>.


=head3 grid_hours

This is the number of hours that one grid will span
(default 4 in portrait mode, 6 in landscape mode).


=head3 heading_baseline

This is the space between the baseline of the heading and the top line
of the grid (default 3).


=head3 heading_font

This is the name of the font used for the date shown above the grid
(default C<Helvetica-Bold>).


=head3 heading_font_size

This is the size of the font used for the date (default 12).


=head3 heading_format

This is the L<CLDR format|DateTime/"CLDR Patterns"> used for the date
shown above the grid (default C<EEEE, MMMM d, y>).


=head3 landscape

If set to a true value, the listings will be printed in landscape mode.
The default is false.


=head3 left_margin

This is the left margin (default 22, or about 0.3 inch).


=head3 line_height

This is the height of a single-line row on the grid (default 10).


=head3 paper_size

This the paper size (default C<Letter>).  See L<PostScript::File/paper>.


=head3 ps_parameters

This is a hashref of additional parameters to pass to
PostScript::File's constructor.  These values will override the
parameters that PostScript::ScheduleGrid generates itself (but you should
reserve this for things that can't be controlled through
other PostScript::ScheduleGrid attributes).


=head3 right_margin

This is the right margin (default 22, or about 0.3 inch).


=head3 time_headers

This is an arrayref of two strings containing the CLDR formats used
for the headers displaying the time (default S<C<['h a', 'h:mm']>>).
The first string is used on the hour, and the second is used on the
half-hour.


=head3 title_baseline

This is the space between the baseline of a resource name or time and
the grid line below it (default 1.6875).


=head3 title_font

This is the name of the font used for resource names & times
(default C<Helvetica-Bold>).


=head3 title_font_size

This is the size of the font used for resource names & times (default 9).


=head3 title_width

This is the width of the resources column in the grid.  By default, it
is calculated to be just wide enough for the longest resource name.


=head3 top_margin

This is the top margin (default 36, or 1/2 inch).


=head2 Other Attributes

You will probably not need to use these attributes unless you are
trying advanced tasks.


=head3 ps

This is the L<PostScript::File> object containing the grid.

=head1 METHODS

=head2 output

  $rpt->output($filename [, $dir]) # save to file
  $rpt->output($filehandle)        # print to open filehandle
  $rpt->output()                   # return as string

This method takes the same parameters as L<PostScript::File/output>.
You can pass a filename (and optional directory name) to store the
listings in a file.  (No extension will be added to C<$filename>, so it
should normally end in ".ps".)

You can also pass an open filehandle (anything recognized by
L<Scalar::Util/filehandle>) to print the PostScript code to that filehandle.
The filehandle will not be closed afterwards.

If you don't pass a filename or filehandle, then the PostScript code
is returned as a string.

=head1 SEE ALSO

L<PostScript::ScheduleGrid::XMLTV>, for creating a grid with TV listings
from L<XMLTV>.

=for Pod::Coverage
^BUILD$
get__PostScript_File

=head1 DIAGNOSTICS

=over

=item C<< %s does not do PostScript::ScheduleGrid::Role::Style >>

A class used as a category style must do the correct role.  The
specified class doesn't.


=item C<< %s is not a supported value for 'lines' in resource %s >>

The number of lines must be a positive integer.  The specified
resource tried to use a different value.


=item C<< All resources must have a name >>

One of the hashrefs in C<resources> did not have a C<name> key.


=item C<< Category name cannot be empty >>

You cannot define the empty string as a category.  Instead of changing
the default style, you must assign every cell a category.


=item C<< Invalid category '%s' in %s event at %s >>

The event associated with the specified resource and start time had a
category that doesn't exist.


=back

=head1 CONFIGURATION AND ENVIRONMENT

PostScript::ScheduleGrid requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-PostScript-ScheduleGrid AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=PostScript-ScheduleGrid >>.

You can follow or contribute to PostScript-ScheduleGrid's development at
L<< https://github.com/madsen/postscript-schedulegrid >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
