# Copyright (C) 2000-2002, Free Software Foundation FSF.

# PPresenter::Viewport::Control
#
# A special version of a viewport: a viewport with controls.
#

package PPresenter::Viewport::Control;

use strict;
use PPresenter::Viewport;
use base 'PPresenter::Viewport';

use PPresenter::Viewport::SlideButtonBar;
use PPresenter::Viewport::ProgressBar;
use PPresenter::Viewport::Neighbours;
use PPresenter::Viewport::BackgroundMenu;
use PPresenter::Viewport::SlideControl;
use PPresenter::Viewport::TagControl;
use PPresenter::Viewport::Phases;

use constant ObjDefaults =>
{ -showSlideNotes     => 0
, -includeControls    => 0
, -resizable          => undef
, -progressColors     => [ 'white', 0.5, 'yellow', 0.7, 'green', 0.9,
                           'orange', 1.1, 'red' ]

# Settings of progress-bar.
, -showProgressBar    => 1
, -progressLineWidth  => 2
, -progressBackground => 'black'
, -slideButtonBackground => 'green'

# Settings of progress-control.
, -showSlideButtons   => 1

# Settings of neighbour slide-names.
, -showNeighbours     => 1
, -neighbourNameColor => 'yellow'
, -neighbourNameSize  => '10p'    # pixels.

# Settings of phase progression display.
, -showPhases         => 1
, -phaseSymbol        => 'image pinkball.gif'
, -phaseLocation      => 'ne'
, -phaseDirection     => 'vertical'
};

sub InitObject(@)
{   my $viewport = shift;

    $viewport->{-resizable} = $viewport->{-showSlideNotes}
        unless defined $viewport->{-resizable};

    $viewport->SUPER::InitObject(@_);

    die "Progress color-list for progress shall have odd length.\n"
        unless (@{$viewport->{-progressColors}} & 1) == 1;

    $viewport;
}

sub createControl()
{   my $viewport = shift;

    my ($show,$screen) = @$viewport{'show', 'screen'};
    my $has_popup = not $viewport->{-includeControls};
    my $where     = $has_popup
                  ? MainWindow->new(-screen => $viewport->{-display})
                  : ($viewport->{controlframe} = $screen->Frame);

    @$viewport{ qw/progressbar slidebar neighbours menu
                   slidecontrol tagcontrol phases/ } =
    ( PPresenter::Viewport::ProgressBar->new($show, $viewport)
    , PPresenter::Viewport::SlideButtonBar->new($show, $viewport)
    , PPresenter::Viewport::Neighbours->new($show, $viewport)
    , PPresenter::Viewport::BackgroundMenu->new($show, $viewport,
         $viewport->{screen}, $has_popup)
    , PPresenter::Viewport::SlideControl->new($show, $viewport, $where)
    , PPresenter::Viewport::TagControl->new($show, $viewport, $where)
    , PPresenter::Viewport::Phases->new($show, $viewport)
    );

    if($has_popup)
    {   $where->withdraw;
        $viewport->make_popup($show, $where,
            $viewport->{slidecontrol}, $viewport->{tagcontrol});

        $viewport->{controlpopup} = $where;
    }
    else
    {   # These two are grouped into a separate frame which is repacked
        # when needed.  The controls do not need to be repacked ever.
        $viewport->getSlideControl->pack(-fill => 'both', -anchor => 'n');
        $viewport->getTagControl->pack(-fill => 'both', -anchor => 'n');
    }

    $viewport->packViewport;
}

sub getProgressBar()   {shift->{progressbar}->getBar}
sub getSlideBar()      {shift->{slidebar}->getBar}
sub getNeighbours()    {shift->{neighbours}->getBar}
sub getSlideControl()  {shift->{slidecontrol}->getControl}
sub getTagControl()    {shift->{tagcontrol}->getControl}

sub setPhase($$)
{   my $viewport = shift;
    $viewport->{phases}->setPhase($viewport->{-showPhases} ? (@_) : (0,0));
}

sub remove_controls()
{   my $viewport = shift;
    $viewport->{-showPhases}       = 0;
    $viewport->{-showProgressBar}  = 0;
    $viewport->{-showSlideButtons} = 0;
    $viewport->{-showNeighbours}   = 0;
    $viewport->packViewport;
}

sub add_controls()
{   my $viewport = shift;
    $viewport->{-showPhases}       = 1;
    $viewport->{-showProgressBar}  = 1;
    $viewport->{-showSlideButtons} = 1;
    $viewport->{-showNeighbours}   = 1;
    $viewport->packViewport;
}

sub showControls($)
{   my ($viewport, $do_show) = @_;
    $do_show ? $viewport->add_controls : $viewport->remove_controls;
    $viewport;
}

sub busy($)
{   my ($viewport, $on) = @_;
    $on ? $viewport->{screen}->Busy : $viewport->{screen}->Unbusy;
    $viewport;
}

sub packViewport()
{   my $viewport = shift;

    # Take all widgets from the viewport.
    my $screen     = $viewport->{screen};
    my @components = $screen->packSlaves;
    @components && map {$_->packForget} @components;

    # Create a normal viewport.

    # Put on the viewport what we need now.
    $viewport->getProgressBar->pack(-side => 'bottom', -fill => 'x')
        if $viewport->{-showProgressBar};

    $viewport->getSlideBar->pack(-side => 'bottom', -fill => 'x')
        if $viewport->{-showSlideButtons};

    $viewport->getNeighbours->pack(-side => 'bottom', -fill => 'x')
        if $viewport->{-showNeighbours};

    $viewport->{controlframe}->pack(-side => 'right', -fill => 'y' )
        if exists $viewport->{controlframe};

    $viewport->{playfield}->pack(-side => 'left', -fill =>'both', -expand=>1);
    $viewport->{show}->showSlide('THIS');   # Recompute: often resize needed.
    $viewport;
}

sub hasControl() { 1 } # yes.

sub clockTic($$)
{   my ($viewport, $interval, $current_slide) = @_;
    $viewport->{slidecontrol}->clockTic($interval, $current_slide);
    $viewport->{progressbar}->clockTic($interval);
}

sub update($$)
{   my ($viewport, $show, $slide) = @_;

    # Update neighbours.
    my ($back,$forward) = ($show->previousSelected, $show->nextSelected);
    my $left  = defined $back    ? "$back"    : '';
    my $right = defined $forward ? "$forward" : '';

    $viewport->{neighbours}->update($left, "$slide", $right);
    $viewport->{slidebar}->update($slide);
    $viewport->{progressbar}
               ->expectedArrival($viewport->{slidebar}->endOfSlide);
    $viewport;
}

sub slideSelectionChanged()
{   my $viewport = shift;
    $viewport->{slidebar}->reconstruct;
    $viewport->{slidecontrol}->selectionChanged;
    $viewport->{tagcontrol}->selectionChanged;
    $viewport;
}

sub make_popup($$$$)
{   my ($viewport, $show, $w, $slidecontrol, $tagcontrol) = @_;

    $w->withdraw;
    $w->iconname('Control');

    my $f = $w->Frame;

    $f->Button
        ( -text       => "Dismiss"
        , -underline  => 0
        , -command    => sub {$w->withdraw}
        )->pack(-side => 'left', -padx=>3,-pady=>3, -fill => 'both');
    $w->bind("<Key-d>", sub {$w->withdraw});

    $f->Checkbutton
        ( -text       => 'Halt'
        , -underline  => 0
        , -variable   => \$show->{-halted}
        , -command    => sub {$show->setRunning}
        , -relief     => 'raised'
        )->pack(-side => 'left', -padx=>3,-pady=>3, -fill => 'both');
    $w->bind("<Key-g>", sub {$show->setRunning(1)} );
    $w->bind("<Key-h>", sub {$show->setRunning(0)} );

    $slidecontrol->getControl->grid($tagcontrol->getControl, -sticky => 'n');
    $f->grid('-', -pady => 5, -padx => 5);

    $w->bind("<Key-n>", sub {$show->showSlide('NEXT_SELECTED');} );
    $w->bind("<Key-N>", sub {$show->showSlide('NEXT');} );
    $w->bind("<Key-p>", sub {$show->showSlide('PREVIOUS');} );

    $w->Advertise(slides => $slidecontrol);
    $w->Advertise(tags   => $tagcontrol);
}

sub showControl()
{   shift->{controlpopup}->Popup(-popover => 'cursor')
}

1;
