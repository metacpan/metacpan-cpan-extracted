# Copyright (C) 2000-2002, Free Software Foundation FSF.

# Viewport
#
# This packages drives the display on one viewport of the slide-show.
#

package PPresenter::Viewport;

use strict;
use PPresenter::Object;
use base 'PPresenter::Object';

use Tk;

use constant ObjDefaults =>
{ -name               => 'default'
, -aliases            => undef

, -display            => $ENV{DISPLAY}
, -device             => 'lcd'
, -geometry           => undef
, -resizable          => 0

, -hasControl         => undef
, -showSlideNotes     => 0
, -style              => undef
, show                => undef
};

sub InitObject()
{   my ($viewport) = shift;
    my $show = $viewport->{show};

    $viewport->SUPER::InitObject;

    $viewport->{selected_style}
        = defined $viewport->{-style}
        ? $show->find(style=>$viewport->{-style})
        : $viewport->showSlideNotes
        ? $show->find(style=>'slidenotes')
        : $show->find(style=>'SELECTED');

    my $screen = MainWindow->new(-screen => $viewport->{-display});
    my $geometry
        = $viewport->{-geometry}
        || $show->{-geometry}
        || sprintf("%dx%d+0+0", $screen->screenwidth, $screen->screenheight);

    $screen->geometry($geometry);

    $screen->resizable(0,0) unless $viewport->{-resizable};
    $screen->appname('PP');

    $viewport->{screen} = $screen;
    $viewport->{playfield} = $screen->Canvas->pack
        (-fill => 'both', -expand => 1);

    $screen->waitVisibility;
    $viewport;
}

sub geometry() {$_[0]->{-geometry}}
sub screen()   {$_[0]->{screen}}
sub canvas()   {$_[0]->{playfield}}
sub style()    {$_[0]->{selected_style}}
sub device()   {$_[0]->{-device}}
sub display()  {$_[0]->{-display}}
sub screenId() {$_[0]->{screen}->id}
sub canvasId() {$_[0]->{playfield}->id}

sub iconify()  {$_[0]->{screen}->iconify; shift}
sub withdraw() {$_[0]->{screen}->withdraw; shift}
sub sync()     {$_[0]->{screen}->update; shift}

#
# Selections
#

sub select($$;)
{   my ($viewport, $type, $name) = @_;

    return $viewport->{selected_style} = $viewport->find(style => $name)
        if $type eq 'style';

    $viewport->{selected_style}->select($type, $name);
}

sub find($$)
{   my ($viewport, $type, $name) = @_;

    return $viewport->{selected_style}
        if $type eq 'style' && $name eq 'SELECTED';

    return $viewport->{show}->find($type, $name)
        if $type eq 'style';

    $viewport->{selected_style}->find($type, $name)
}

sub styleElems($)
{   my ($viewport, $slide, $flags) = @_;
    my $style = exists $flags->{style}
              ? $viewport->{show}->find(style => $flags->{style})
              : $viewport->{selected_style};
    $style->styleElems($slide, $flags);
}

sub font(@)
{   my $viewport = shift;
    $viewport->find(fontset => 'SELECTED')->font($viewport, @_);
}

#
# Slides
#

sub setSlide($$)
{   my ($viewport,$slide,$newtag) = @_;
    my $tag = $viewport->{current_tag};
    $viewport->canvas->delete($tag) if defined $tag;
    $viewport->{current_slide} = $slide;
    $viewport->{current_tag}   = $newtag;
}

sub packViewport(;)
{   $_[0]->{playfield}
         ->pack(-side => 'top', -expand => 1, -fill => 'both');
}

sub showSlideNotes    {$_[0]->{-showSlideNotes}}
sub hasControl        { 0 }

sub backgroundId()    {$_[0]->{background_id}}
sub setBackgroundId() {$_[0]->{background_id} = $_[1]}

#
# Program
#

sub startProgram(@)
{   my ($viewport, $program) = @_;
    $viewport->{program} = $program;
    $program->start;
    $viewport;
}

sub removeProgram(;)
{   my $viewport = shift;
    return unless $viewport->{program};
    $viewport->{program}->removeProgram;
    undef $viewport->{program};
    $viewport;
}

sub nextProgramPhase($)   {$_[0]->{program}->nextPhase}

#
# Geometry
#

sub canvasDimensions()
{   my $canvas = shift->{playfield};
    ($canvas->width, $canvas->height);
}

sub screenMessures()
{   my $viewport = shift;

    unless(defined $viewport->{width})
    {   my $screen = $viewport->screen;
        @$viewport{'width','height'} = ($screen->width, $screen->height);
    }

    return @$viewport{'width','height'};
}

sub findClosestsGeometry($@;)
{   my $viewport = shift;

    my ($width, $height) = $viewport->screenMessures;
    my ($best, $prefer);

    foreach (@_)
    {   my ($w, $h) = split /x/;
        my $distance = ($width-$w)*($width-$w)+($height-$h)*($height-$h);
        next if defined $best && $best < $distance;

        $best = $distance;
        $prefer = $_;
    }

    return $prefer;
}

sub geometryScaling($;$)    # args is (geometry) or (width,height)
{   my $viewport = shift;
    my ($w, $h)  = (@_ == 1 ? $_[0] =~ m/(\d+)x(\d+)/ : @_);
 
    my ($width, $height) = $viewport->screenMessures;
    my $twodim = ($width*$height) / ($w*$h);
    return sqrt($twodim);
}

sub Photo(@) {shift->canvas->Photo(@_)}

1;
