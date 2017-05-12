# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Viewport::ProgressBar;

use Tk;
use strict;

sub new($$)
{   my ($class, $show, $viewport) = @_;

    my $width = $viewport->{-progressLineWidth};

    my $display  = $viewport->screen->Canvas
       ( -background => $viewport->{-progressBackground}
       , -height     => 2*$width+3
       );

    my $self = bless
    { display    => $display
    , show       => $show
    , lineWidth  => $width
    , colorScale => $viewport->{-progressColors}
    , runtime    => 0
    , totaltime  => $show->{-totaltime}
    }, $class;

    $display->createLine(0,0,0,0, -tags => 'timeleft',  -width => $width);
    $display->createLine(0,0,0,0, -tags => 'timeshort', -width => $width);

    $self;
}

sub getBar($)          { $_[0]->{display} }
sub expectedArrival($) { $_[0]->{perc_of_show} = $_[1] }

sub clockTic($)
{   my ($self, $interval) = @_;
    my ($show, $display)  = @$self{'show','display'};

    $self->{runtime} += $interval;

    # Find color to be used.
    my $on_time = $self->{runtime}/($self->{totaltime}*$self->{perc_of_show});
    @_ = @{$self->{colorScale}};
    shift, shift until !defined $_[1] || $_[1] > $on_time;
    my $color = $_[0];

    my $lw         = $self->{lineWidth};
    my ($y1,$y2)   = (1 + $lw, 1+$lw+1+$lw);
    my $margin     = 4;
    my $max_width  = $display->width - 2*$margin;

    my $progress   = $self->{runtime} / $self->{totaltime};
    if($progress < 1.0)
    {   $display->itemconfigure('timeleft',  -fill => $color);
        $display->coords('timeleft',
                         $margin,$y1, $margin+$progress*$max_width, $y1);
    }
    else
    {   $display->itemconfigure('timeleft',  -fill => $color);
        $display->itemconfigure('timeshort', -fill => $color);
        $display->coords('timeleft',  $margin,$y1, $margin+$max_width, $y1);
        $progress -= 1.0;
        $progress  = 1.0 if $progress > 1.0;

        $display->coords('timeshort',
                      $margin+$max_width-$progress*$max_width,$y2,
                      $margin+$max_width, $y2);
    }
}

1;
