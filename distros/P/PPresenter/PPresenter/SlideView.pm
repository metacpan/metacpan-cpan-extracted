# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::SlideView;

use strict;
use PPresenter::Object;
use base 'PPresenter::Object';

sub new($$$)
{   my ($class, $show, $slide, $style_flags, $viewport) = @_;

    # Collect the options from (sub-classes of) Slide.
    my $view = bless
    { -name          => "Slide $slide view $viewport"
    , show           => $show
    , slide          => $slide
    , viewport       => $viewport
    , canvas         => $viewport->canvas
    , style_elements => $viewport->styleElems($slide, $style_flags)
    , id             => undef
    }, $class;

    $view->getOptions($class)->InitObject;
}

sub setOptions($) {$_[0]->{options} = $_[1]}
sub decoration()  {shift->{decoration}}
sub fontset()     {shift->{fontset}   }
sub formatter()   {shift->{formatter} }
sub template()    {shift->{template}  }
sub dynamic()     {shift->{dynamic}   }

sub viewport()    {shift->{viewport}  }
sub showsOnViewport($) {"$_[0]->{viewport}" eq "$_[1]"}
sub canvas()      {shift->{viewport}->canvas}
sub device()      {shift->{viewport}->device}

sub nextPhase()   {shift->{program}->nextPhase}
sub inLastPhase() {shift->{program}->inLastPhase}
sub gotoPhase($)  {shift->{program}->gotoPhase(@_)}
sub phase()       {shift->{program}->phase}
sub image(@)      {shift->{show}->image(@_)}
sub id()          {shift->{id}}

sub exportedPhases()
{   my $view = shift;
    $view->{dynamic}->exportedPhases($view->{program});
}

sub canvasDimensions()   # often requested, hence answer is cached.
{   my $view = shift;

    $view->{dims} = [ $view->{viewport}->canvasDimensions ]
        unless exists $view->{dims};

    @{$view->{dims}};
}

#
# Just passing on...
#

sub hasBackdrop()
{   my $view = shift;
    $view->{decoration}->hasBackdrop($view->{viewport}->device);
}

sub color(@)
{   my $view = shift;
    $view->{decoration}->color($view, @_);
}

sub findFontSize($@)
{   my $view = shift;
    $view->{fontset}->findFontSize($view->{viewport}, @_);
}

sub font(@)   {shift->{fontset}->font(@_)}
sub title()   {shift->{template}->title}

sub nestImage($)
{   my ($view, $name) = @_;
    my ($geom, $img) = $view->{decoration}->nestImageDef($name);

    $view->{show}->image
      ( (ref $img ? $img : (-file => $img))
      , (defined $geom
         ? (-sizeBase => $geom, -resize => 0)
         : (-resize => 0)
        )
      );
}

#
#
#

sub makeBackground()
{   my $view = shift;

    $view->{viewport}->setBackgroundId(
        $view->{decoration}->makeBackground
           ( $view->{viewport}->backgroundId
           , @$view{qw/show slide viewport/}
           ));
}

# Just before a slide is presented, the user-spec is merged with
# the style-element description.  When the slide is removed from
# display, the merge is removed again, because it consumes quite
# a lot of memory.

sub explode($$)
{   my ($view, $slide, $options) = @_;

    foreach (keys %{$view->{style_elements}})
    {   my $elem = $view->{style_elements}{$_}->copy;

        foreach (keys %$options)
        {   next unless exists $elem->{$_};
            $elem->{$_} = $options->{$_};
        }

        $view->{$_} = $elem;
    }

    $view;
}

sub implode
{   my ($view, $slide) = @_;

    map {delete $slide->{$_}}
        keys %{$view->{style_elements}};

    $view;
}

# This is a dirty trick: to collect all options of all style elements
# into one hash, I shape-shift the hash from elem to elem.  Blurk!

sub collectOptions($)
{   my ($view,$collection) = @_;
    foreach (keys %{$view->{style_elements}})
    {   my $class = ref $view->{style_elements}{$_};
        bless $collection, $class;
        $collection->getOptions($class);
    }
    $view;
}

my $unique_id = 0;

sub prepare($$)
{   my ($view, $slide) = @_;

    $view->explode($slide, $view->{options});

    my $displace_x = defined $view->{displace_x}
                   ? $view->{displace_x}
                   : ($view->{displace_x} = $view->{canvas}->width+10);

    my $show       = $view->{show};
    $view->{program} = $view->dynamic->makeProgram($show, $view, $displace_x);

    $view->{id} = "s".$unique_id++;
    $view->template->prepareSlide($show, $slide, $view)
                   ->createSlide($show, $slide, $view, $displace_x);

    $view->implode($slide);
}

sub show($)
{   my ($view,$slide) = @_;
    $view->{viewport}->setSlide($slide, $view->{id});
    $view;
}

#
# Program
#

sub addProgram($$)
{   my ($view, $string, $tag_or_callback) = @_;
    $view->{dynamic}
         ->parse($view->{program}, $view->{slide}, $tag_or_callback, $string);
}

sub startProgram()
{   my $view = shift;
    $view->{viewport}->startProgram($view->{program});
}

sub removeProgram()
{   delete shift->{program};
}

1;
