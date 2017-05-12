# Copyright (C) 2000-2002, Free Software Foundation FSF.

#
# SlideControl
# A window which shows the available slides plus required and used
# time.

package PPresenter::Viewport::SlideControl;

use strict;
use Tk;
use Tk::LabFrame;
use Tk::Table;
use PPresenter::tkTimerLabel;

sub new($$$)
{   my ($class, $show, $info, $screen) = @_;

    my $control = $screen->LabFrame
        ( -label       => 'slides'
        , -labelside   => 'acrosstop'
        );

    my $self = bless
       { show    => $show
       , info    => $info
       , control => $control
       }, $class;

    my $totaltime = $show->{-totaltime};
    my @slides    = $show->slides;

    my $table = $control->Table
        ( -scrollbars => (@slides < 15 ? '' : 'w')
        , -rows       => 15
        , -fixedrows  => 1
        )->pack(-side => 'left');

    my $row = 0;

    $self->{sumtime} = $table->TimerLabel
        ( -value      => 0
        , -maxValue   => $totaltime
        , -colorScale => $info->{-progressColors}
        );
    $table->put($row, 0, $self->{sumtime});

    $self->{selected_text} = '';
    $table->put($row, 1, $table->Label
        ( -textvariable => \$self->{selected_text}
        , -justify    => 'left'
        ));

    $self->{runtime} = $table->TimerLabel
        ( -value      => 0
        , -maxValue   => $totaltime
        , -colorScale => $info->{-progressColors}
        );
    $table->put($row++, 2, $self->{runtime});

    foreach my $slide (@slides)
    {   my ($max, $name, $spent) = $slide->statusButtons($show, $table,
           , $info->{-progressColors}
           , [ sub {$show->showSlide($_[0])}, $slide->number ]
           );

        push @{$self->{spent_buttons}}, $spent;
        $table->put($row, 0, $max);
        $table->put($row, 1, $name);
        $table->put($row, 2, $spent);
        $row++;
    }

    $self;
}

sub getControl() {$_[0]->{control}}

sub selectionChanged()
{   my $self          = shift;

    my $control       = $self->{control};

    my $sumtime         = 0;
    my $selected_slides = 0;

    foreach ($self->{show}->slides)
    {   next unless $_->isActive;
        $sumtime += $_->requiredTime;
        $selected_slides++;
    }

    $self->{selected_text}   = sprintf "$selected_slides slides on";
    $self->{sumtime}->setValue($sumtime);

    $self;
}

sub clockTic($$)
{   my ($self, $interval, $current_slide) = @_;

    $self->{runtime}->configure(-step => $interval);
    $self->{spent_buttons}[$current_slide->number]
         ->configure(-step => $interval);
}

1;
