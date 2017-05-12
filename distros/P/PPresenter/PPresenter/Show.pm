# Copyright (C) 2000-2002, Free Software Foundation FSF.

# SHOW
#
# This packages drives the slide-show, while the main package is
# used to limit the user's access to the routines.
#

package PPresenter::Show;

use strict;
use Carp;

use PPresenter::Object;
use base 'PPresenter::Object';

use PPresenter::Viewport;
use PPresenter::Viewport::Control;
use PPresenter::Slide;
use PPresenter::StyleElem;
use PPresenter::Images;

use constant ObjDefaults =>
{ -name               => 'Portable Presenter'
, -aliases            => undef

, -trace              => '/dev/null'    # /dev/tty is also useful ;)

, -geometry           => undef
, -controlDisplay     => undef          # $ENV{DISPLAY}
, -controlGeometry    => '640x480'
, -imageSizeBase      => undef
, -resizeImages       => 1
, -enlargeImages      => 0
, -scaledImagesDir    => undef

, -style              => undef          # or use $show->addStyle
, -styles             => undef

, -startSlide         => 'FIRST'
, -totaltime          => undef
, -tags               => undef   # initial selection of sites.
, -flushPhases        => 0
, -enableCallbacks    => 1
, -clockTics          => 1.0
, -halted             => 1
};

sub InitObject(@)
{   my $show = shift;

    $show->SUPER::InitObject(@_);

    # own exit executes END, default does not.
    $SIG{INT} = $SIG{QUIT} = $SIG{TERM} = sub {exit};

    my $tracefile = $show->{-trace};
    open (PPresenter::TRACE, ">$tracefile")
        or die "Unable to open file $tracefile for trace.\n";

    $show->{slides}    = [];
    $show->{exporters} = [];

    # Styles.

    $show->add('style'
    , 'PPresenter::Style::Default'
    , 'PPresenter::Style::SlideNotes'
    );

    $show->add(style => $show->{-style})
        if defined $show->{-style};

    $show->add(style => @{$show->{-styles}})
        if defined $show->{-styles};

    $show->{selected_style} = $show->find_style('default')
                            || $show->find_style('FIRST');

    $show->{-totaltime} = $show->time2secs($show->{-totaltime})
         if defined $show->{-totaltime};

    # Images.

    $show->{images} = PPresenter::Images->new
    ( show   => $show
    , tmpdir => $show->{-scaledImagesDir} || undef
    );

#   warn "Define -scaledImagesDir to safe scaled images.\n"
#     if $^W && !defined $show->{-scaledImagesDir};

    $show;
}

sub remove_dir($)
{   my ($show, $dir) = @_;

    unless(opendir D, $dir)
    {   die "Couldn't open directory $dir to cleanup.\n";
        return;
    }

    while(defined (my $item = readdir D))
    {   my $path = "$dir/$item";
        if($item eq '.' || $item eq '..') {}
        elsif(-d $path) {$show->remove_dir($path) }
        else            {unlink "$path"}
    }

    closedir D;
    rmdir $dir;
}
 
#
# Find
#

sub find($;$)
{   my ($show, $type, $name) = @_;

    $name = 'SELECTED' unless defined $name;

    my $object = $type eq 'main'     ? $show
               : $type eq 'slide'    ? $show->find_slide($name)
               : $type eq 'viewport' ? $show->find_viewport($name)
               : $type eq 'style'    ? $show->find_style($name)
               : $type eq 'image'    ? $show->{images}->findImage($name)
               : $show->{selected_style}->find($type, $name);

    die "Cannot find $type $name.\n"
        unless defined $object;

    $object;
}

#
# Select
#

sub select($$)
{   my ($show, $type, $name) = @_;

    return $show->{selected_viewport} = $show->find_viewport($name)
        if $type eq 'viewport';

    if($type eq 'slide')
    {   warn "Cannot select a slide.\n";
        return undef;
    }

    return $show->{selected_style}->select($type, $name)
        unless $type eq 'style';

    my $style = $show->find_style($name);
    unless(defined $style)
    {   warn "Cannot find style $name.\n";
        return undef;
    }

    map {$_->select(style => $style)} @{$show->{viewports}};
}

sub add($$@)
{   my ($show, $type) = (shift, shift);

    return $show->addSlide(@_)    if $type eq 'slide';
    return $show->addViewport(@_) if $type eq 'viewport';
    return $show->addStyle(@_)    if $type eq 'style';
    return $show->image(@_)       if $type eq 'image';

    $show->{selected_style}->add($type, @_);
}

sub changeDefaults($$@)
{   my ($show, $type, $name) = (shift, shift, shift);

    return $show->change_viewport($name, @_)
        if $type eq 'viewport';

    return $show->{selected_style}->change($type, $name, @_)
        if $type ne 'style';

    return map {$_->change(@_)} $show->find_style('ALL')
        if $name eq 'ALL';

    my $style = $show->find_style($name);
    warn "Can't find style $name to change.\n", return
         unless defined $style;

    $show->addStyle($style->change(@_));
}

#
# Viewports
#

sub hasViewports()
{   my $show = shift;
    return 0 unless defined $show->{viewports};
    foreach (@{$show->{viewports}})
    {   return 1 unless $_->showSlideNotes;
    }
    return 0;
}

sub addViewport(@)
{   my $show = shift;

    die "Add viewports (screens) before the first slide.\n"
        if @{$show->{slides}};

    shift while @_ > 0 && !defined $_[0];  # skip undefs.
    return unless @_;                      # nothing to add.

    # Make flat arglist to hash.
    return $show->addViewport( {@_} )
        unless ref $_[0];

    return map {$show->addViewport($_)} @{$_[0]}
        if ref $_[0] eq 'ARRAY';

    my $proto  = shift;
    my $screen = $proto->{-hasControl} || 0
               ? PPresenter::Viewport::Control->new(%$proto, show => $show)
               : PPresenter::Viewport->new(%$proto, show => $show);

    print PPresenter::TRACE "Defined viewport $screen.\n";

    push @{$show->{viewports}}, $screen;
    $screen;
}

sub findControlViewport()
{   my $show = shift;

    my @controls = grep {$_->hasControl} @{$show->{viewports}};
    die "No viewport has control (-hasControl=>1).\n" unless @controls;
    die "Two show controls defined: @controls.\n" if @controls > 1;

    $controls[0];
}

sub find_viewport($)
{   my ($show, $name) = @_;

    $show->initViewports;

    return $show->{selected_viewport} if $name eq 'SELECTED';
    PPresenter::Viewport->fromList($show->{viewports}, $name);
}

sub change_viewport($@)
{   my ($show, $name) = (shift, shift);
    $show->initViewports;
 
    return map {$_->change(@_)} @{$show->{viewports}}
        if $name eq 'ALL';

    my $viewport = $show->find_style($name);
    warn "Can't find viewport $name to change.\n", return
         unless defined $viewport;

    $viewport->change(@_);
}

sub showSlideControl()   {$_[0]->{control}->showControl }
sub updateSlideControl() {$_[0]->{control}->updateSlides}
sub iconifyControl()     {$_[0]->{control}->iconify     }
sub viewports()          {@{$_[0]->{viewports}}         }

sub initViewports()
{   my $show = shift;

    return if exists $show->{viewports_initialized};
    $show->{viewports_initialized} = 1;

    unless($show->hasViewports)
    {   $show->addViewport
        ( -name            => 'default'
        , -hasControl      => ! defined $show->{-controlDisplay}
        );
    }

    $show->addViewport
        ( -name            => 'control'
        , -display         => $show->{-controlDisplay}
        , -geometry        => $show->{-controlGeometry}
        , -hasControl      => 1
        , -includeControls => 1
        , -style           => 'slidenotes'
        , -showSlideNotes  => 1
        ) if defined $show->{-controlDisplay};

    $show->{selected_viewport} = $show->find_viewport('default')
                              || $show->find_viewport('FIRST');

    # Find-out which window has the controls.
    my @controls = grep {$_->hasControl} @{$show->{viewports}};
    die "Two show controls defined: @controls.\n" if @controls > 1;
    die "No viewport has control.\n" unless @controls;

    $show->{control} = $controls[0];
    $show;
}

#
# Styles
#

sub addStyle(@)
{   my $show = shift;

    shift while @_ > 0 && !defined $_[0];
    return unless @_;

    return map {$show->addStyle($_)} @_  if @_>1;
    return map {$show->addStyle($_)} @$_ if ref $_ eq 'ARRAY';

    my $style = shift;
    if(ref $style && $style->isa('PPresenter::Style'))
    {   unshift @{$show->{styles}}, $style;
        return $show;
    }

    die "$style is not a style.\n" if ref $style;

    push @{$show->{styles}},
       PPresenter::StyleElem::load($style, show => $show);
}

sub find_style($)
{   my ($show, $name) = @_;

    return $show->{selected_style} if $name eq 'SELECTED';
    PPresenter::Style->fromList($show->{styles}, $name);
}

#
# Slides
#

sub addSlide(@)
{   my $show  = shift;

    $show->initViewports;

    unless (ref $_[0])  # list of strings: one slide.
    {   my $slide = PPresenter::Slide->new(show => $show, @_);
        push @{$show->{slides}}, $slide;
        return $slide;
    }

    my @slides;
    foreach (@_)
    {   if(ref $_ eq 'ARRAY')
        {   push @slides, $show->addSlide(@$_);
        }
        elsif($_->isa('PPresenter::Slide'))
        {   push @{$show->{slides}}, $_;
            push @slides, $_;
        }
        else
        {   die "You tried to add a ", ref $_, " named \"$_\" as slide.\n";
        }
    }
}

sub includeShow($)
{   my ($show, $show2) = @_;
    $show->addSlide($show2->slides);
}

sub find_slide($)
{   my ($show, $name) = @_;
    $name = 'LAST' unless defined $name;
    $name = 'LAST' if $name eq 'SELECTED';
    PPresenter::Slide->fromList($show->{slides}, $name);
}

sub slides()       { @{shift->{slides}} }
sub activeSlides() { grep {$_->isActive} @{shift->{slides}} }
sub numberSlides() { scalar @{shift->{slides}} }
sub current()      { shift->{current_slide} }

sub containsSlideNotes()
{   my $show = shift;
    foreach ($show->slides)
    {   return 1 if $_->hasSlideNotes;
    }
    return 0;
}

#
# Program
#

sub mustFlushPhases()      { shift->{-flushPhases} }
sub flushPhases()          { shift->addPhase(9)    }
sub updatePhaseSymbols($$) { shift->{control}->setPhase(@_) }

sub addPhase($)
{   my ($show, $count) = @_;
    $show->{current_slide}->nextPhase while $count-- > 0;
}

sub nextSelected($;)
{   my $show = shift;
    my $current = $show->{current_slide};

    while(defined $current)
    {   $current = $show->find_slide(defined $current->{-nextSlide}
                    ? $current->{-nextSlide} : $current->{number} +1);

        return $current if defined $current && $current->isActive;
    }

    return undef;
}

sub previousSelected()
{   my $show = shift;
    my $current = $show->{current_slide};

    while(defined $current)
    {   $current = $show->find_slide($current->number -1);
        return $current if defined $current && $current->isActive;
    }

    return undef;
}

#
# Slide
#

sub showSlide($)
{   my ($show, $next_slide) = @_;
    return unless defined $next_slide;

    my $slides  = $show->{slides};
    my $current = $show->{current_slide};

    if(ref $next_slide ne '' && $next_slide->isa("PPresenter::Slide"))
    {   return if "$next_slide" eq "$current";
        $next_slide->{previous} = $current;
    }
    elsif($next_slide eq 'FIRST')
    {   $next_slide = $show->find_slide(0);
        return unless defined $next_slide;
        $next_slide->{previous} = $current || $next_slide;
    }
    elsif($next_slide eq 'LAST')
    {   $next_slide = $show->find_slide($#{$slides});
        return unless defined $next_slide;
        $next_slide->{previous} = $current;
    }
    elsif($next_slide eq 'BACK')
    {   return if $current->{number}==0;
        $next_slide = $show->find_slide($current->{previous} || undef);
        return unless defined $next_slide;
        $next_slide->{previous} = $current;
    }
    elsif($next_slide eq 'NEXT')
    {   return if $current->{number} == $#$slides;
        $next_slide = $show->find_slide($current->{-nextSlide} || $current->{number} +1);
        return unless defined $next_slide;
        $next_slide->{previous} = $current;
    }
    elsif($next_slide eq 'NEXT_SELECTED')
    {
        $next_slide = $show->nextSelected;
        return unless defined $next_slide;
        $next_slide->{previous} = $current;
    }
    elsif($next_slide eq 'PREVIOUS')
    {   $next_slide = $show->previousSelected;
        return unless defined $next_slide;
        $next_slide->{forward} = $current;
    }
    elsif($next_slide eq 'FORWARD')
    {   $next_slide = $show->find_slide($current->{forward} || undef);
        return unless defined $next_slide;
    }
    elsif($next_slide eq 'THIS')
    {   $next_slide = $current;
    }
    elsif($next_slide !~ /\D/)   # is a number
    {   $next_slide = $show->find_slide($next_slide);
    }

    return unless defined $next_slide;

    undef $show->{proceed_after};

    print $show->timeStamp,": showing $next_slide->{number} \"$next_slide\".\n";

    # Show new slide.

    $show->busy(1);
    $next_slide->prepare->show;
    $show->busy(0);

    $show->{current_slide}        = $next_slide;
    $show->{current_slide_number} = $next_slide->{number};

    $show->{control}->update($show, $next_slide)->sync;
    $next_slide->startProgram($show);
}

# Some of the information about the show will be copied to the presenter,
# but most not.

# The information stored for each object should contain all necessary
# information to produce the windows, because one must be able to switch
# between slides at random.

sub run()
{
    my $show = shift;

    die "No options allowed for run()" if @_;

    unless(defined $show->{slides})
    {   warn "No slides to show.";
        return;
    }

    # Initialize tags.

    $show->selectTags($show->{-tags})
       if defined $show->{-tags};

    # Initialize time.

    my $totaltime = $show->{-totaltime};
    my $slides    = $show->{slides};
    my $sumtime   = 0;
    my $not_active= 0;

    foreach (@$slides)
    {   if($_->isActive) { $sumtime += $_->requiredTime }
        else             { $not_active++ }
    }

    unless(defined $totaltime)
    {   print "Total time $sumtime seconds for ",
               @$slides-$not_active, " slides.\n";
        $show->{-totaltime} = $sumtime;
    }
    elsif($sumtime > $totaltime)
    {   my $load = $sumtime/$totaltime;
        warn "Your ", @$slides-$not_active, " slides take $sumtime",
             " seconds but you have only $totaltime seconds (",
             int($load*100-100), "% too much)\n";
    }
    elsif($sumtime < $totaltime)
    {   my $load  = $sumtime/$totaltime;
        my $spare = $totaltime - $sumtime;
        $spare    = $spare > 180
                  ? int($spare/60 + .5)." minutes"
                  : $spare." seconds";

        print "You have $spare spare on the "
            , @$slides-$not_active, " slides"
            , " (", 100-int($load*100), "% too short)\n";
    }

    print +($not_active==1 ? "One slide is" : "$not_active slides are"),
        " not selected to be displayed.\n"
            if $not_active;

    # Fill-in all controls.

    $show->{control} = $show->findControlViewport
       unless defined $show->{control};

    $show->{control}->createControl;
    $show->slideSelectionChanged;

    # Schedule to start the show.

    $show->{runtime} = 0;
    my $ascreen = $show->{control}->screen;
    $ascreen->after(100, [ \&start, $show ] );

    use Tk;
    MainLoop;
}

#
# Show main control
#

sub stop
{   my $show = shift;

    print $show->timeStamp, ": show stopped\n";
    exit 0;
}

sub start
{   my $show = shift;

    # When realization is slow, we have to wait for it.
    my $ascreen = $show->{control}->screen;
    $ascreen->after(100) until $ascreen->width > 1;

    $show->showSlide($show->{-startSlide});

    $show->{-starttime} = time;
    print $show->timeStamp,": show started\n";

    $ascreen->repeat(int ($show->{-clockTics}*1000), [ \&clockTic, $show ] );
}

#
# Tags
#

sub selectTags(@)
{   my $show = shift;
    foreach (@_)
    {   my $tag;
       if(ref $_ eq 'ARRAY')           {$show->selectTags(@$_)}
        elsif(($tag) = /^\s*\-(\w+)/ ) {$show->clearTag($tag) }
        elsif(($tag) = /^\s*\+?(\w+)/) {$show->setTag($tag)   }
        else {warn "Do not understand tag specification $_.\n"; }
    }
}

sub setTag($)
{   my ($show, $tag) = @_;
    map {$_->setActive(1) if $_->hasTag($tag)} @{$show->{slides}};
    $show->slideSelectionChanged;
}

sub clearTag($)
{   my ($show, $tag) = @_;
    map {$_->setActive(0) if $_->hasTag($tag)} @{$show->{slides}};
    $show->slideSelectionChanged;
}

sub countSelectedTags()
{   my $show = shift;
    my (%count, %set, %clear);

    foreach (@{$show->{slides}})
    {   if($_->isActive) {map {$set{$_}++;   $count{$_}++} $_->tags}
        else             {map {$clear{$_}++; $count{$_}++} $_->tags}
    }

    map { [ $_, $count{$_}, $set{$_}||0, $clear{$_}||0 ] }
        sort keys %count;
}

sub slideSelectionChanged() {shift->{control}->slideSelectionChanged}
sub busy($)   {my ($show, $busy) = @_; $show->{control}->busy($busy)}

#
# TickTac
#

sub clockTic($)
{   my $show = shift;

    my $interval = $show->{-clockTics};
    my $slide    = $show->{current_slide};

    if($show->{-halted})
    {   $slide->suspended($interval);
        return $show;
    }

    $show->{runtime} += $interval;
    $show->{control}->clockTic($interval, $slide);

    $show->showSlide('NEXT_SELECTED') if $slide->wantNextSlide;
    $show;
}

sub setRunning($)
{   my ($show,$running) = @_;

    $show->{-halted} = not $running
         if defined $running;

    my $status = $show->{-halted}
               ? 'halted'
               : $show->{runtime} > 0 ? 'continues' : 'started';
    print $show->timeStamp,": run $status.\n";
}

sub setProceedAfter($) {$_[0]->{proceed_after} = $_[1]}
sub enableCallbacks()
{   my $show = shift;
    my $old  = $show->{-enableCallbacks};
    $show->{-enableCallbacks} = shift if @_;
    $old;
}

sub minSecs($)
{   my $secs = int $_[1];

    return "??:??" unless defined $secs;

    my $mins = 0;

    if($secs > 60)
    {   $mins = int($secs/60);
        $secs -= $mins*60;
    }

    sprintf "%2d:%02d",$mins,$secs;
}

sub timeStamp(;$)
{   my $show = shift;
    my $tic  = shift || time;
    my ($sec, $min, $hour) = localtime $tic;

    sprintf "%02d:%02d:%02d (%s)",
        $hour, $min, $sec, $show->minSecs($show->{runtime});
}

sub time2secs($)
{   my ($show, $string) = @_;
    my ($hours, $mins, $secs);

    if( ($hours, $mins, $secs)
         = $string =~ /^\s*(?:(\d+)h)?         # hours
                        \s*(?:(\d+)m)?         # minutes
                        \s*(?:(\d+)s?)?\s*$/x) # seconds
    {}
    elsif( ($hours,$mins,$secs)
         = $string =~ /^\s*(?:(?:(\d+):)?      # hours
                                 (\d*):)?      # minutes
                        \s*:?(\d*)\s*$/x)      # seconds
    {}
    else
    {   warn "Cannot understand time specification: $string.\n";
        return 60;
    }

    ($hours||0)*3600 + ($mins||0)*60 + ($secs||0);
}

#
# Images
#

sub image(@)         {shift->{images}->image(@_)}
sub imageSizeBase()  {shift->{-imageSizeBase}}
sub resizeImages()   {shift->{-resizeImages}}
sub enlargeImages()  {shift->{-enlargeImages}}
sub addImageDir(@)   {shift->{images}->addImageDir(@_)}
sub Photo(@)         {shift->{selected_viewport}->Photo(@_)}
sub findImageFile(@) {shift->{images}->findImageFile(@_)}
sub printSlide()     {shift->{current_slide}->print }

#
# Bootstrapping Exporters
#

sub addExporter($@)
{   my ($show, $name) = (shift,shift);

    if(ref $name eq '')
    {   eval "require $name";
        if($@)
        {   croak "Cannot use export $name: $@.\n";
            return undef;
        }

        my $exporter = $name->new(@_);

#       die "$name is not an exporter module.\n"
#           unless $exporter->isa('PPresenter::Export');

        push @{$show->{exporters}}, $exporter;
        print PPresenter::TRACE "Loaded exporter $exporter.\n";
        return $exporter;
    }

    if($name->isa('PPresenter::Exporter'))
    {   push @{$show->{exporters}}, $name->change(@_);
        print PPresenter::TRACE "Added exporter $name.\n";
        return $name;
    }

    warn "WARNING: addExporter expects a module-name.\n";
    return undef;
}

sub exporters() {@{shift->{exporters}}}

my $image_magick_installed;

sub hasImageMagick()
{   my $show = shift;

    unless(defined $image_magick_installed)
    {   eval 'require Image::Magick';
        $image_magick_installed = ($@ eq '');
        warn "Improve image quality by installing Image::Magick.\n"
            unless $image_magick_installed;
    }

    return $image_magick_installed;
}

sub runsOnX()
{   my $show = shift;
    exists $ENV{DISPLAY};
}

#
# Decorations
#

sub decodata($)   # maintains decoration information over slide-bounds.
{   my ($show, $view) = @_;
    my $label = 'deco_'.$view->viewport;
    exists $show->{$label} ? $show->{$label} : ($show->{$label} = {});
}
 
1;
