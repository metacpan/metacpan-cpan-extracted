# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Viewport::SlideButtonBar;

use strict;
use Tk;
use Tk::Balloon;

sub getBar() { $_[0]->{control} }

sub new($$$)
{   my ($class, $show, $viewport) = @_;

    my $control = $viewport->screen->Frame
        ( -height     => 12
        , -background => 'black'
        , -foreground => 'yellow'
        , -borderwidth=> 3
        );

    my $self = bless
    { control    => $control
    , off_color  => $viewport->{-progressBackground}
    , on_color   => $viewport->{-slideButtonBackground}
    , show       => $show
    }, $class;

    my $totaltime = $show->{-totaltime};

    my $when  = 0;
    my $count = 0;

    foreach my $slide ($show->slides)
    {   my $info   = "Undefined";
        my $button = $self->make_button($control
            , [ \&select_slide, $self, $count++ ]
            , \$info
            );
        push @{$self->{buttons}}, [ $slide, $button, \$info, 0 ];
    }

    $self;
}

sub reconstruct()
{   my $self = shift;

    my $control = $self->{control};

    # Remove all buttons, displayed so far.
    my @buttons = $control->placeSlaves();
    @buttons && map {$_->placeForget()} @buttons;

    my $when            = 0;
    my $buttonheight    = $control->cget(-height)-4;

    my $sumtime = 0;
    foreach (@{$self->{buttons}})
    {   my $slide = $_->[0];
        $sumtime += $slide->requiredTime if $slide->isActive;
    }

    foreach (@{$self->{buttons}})
    {   my ($slide, $button, $info, $old_when) = @$_;

        my $reqtime = $slide->requiredTime;
        $_->[3] = ($when+$reqtime)/$sumtime;
        next unless $slide->isActive;

        $button->place
           ( -relx    => $when/$sumtime
           , -relwidth=> $reqtime/$sumtime
           , '-y'     => 0
           , -height  => $buttonheight
           );

        $$info  = $self->make_info($slide, $when);
        $when  += $reqtime;
    }

    $self;
}

sub endOfSlide()
{   my $self = shift;
    return 0 unless defined $self->{displayed};
    my ($slide,$button,$info,$when) = @{$self->{buttons}[$self->{displayed}]};
    $when;
}

sub select_slide($)
{   my ($self, $slide) = @_;
    $self->{show}->showSlide($slide);
}

sub update($)
{   my ($self, $next) = @_;

    $self->{buttons}[$self->{displayed}][1]->configure
        (-background => $self->{off_color})
            if defined $self->{displayed};

    my $number = $next->{number};

    $self->{buttons}[$number][1]->configure
        (-background => $self->{on_color});

    $self->{displayed} = $number;
    $self;
}

#
# Button for one slide.
#

sub make_button($$$;)
{   my ($self, $w, $command, $info) = @_;

    my $button = $w->Button
        ( -text       => ''
        , -relief     => 'sunken'
        , -background => $self->{off_color}
        , -command    => $command
        , -height     => 4
        );

    $button->Balloon(-balloonposition => 'mouse')
           ->attach($button, -msg => $info);

    return $button;
}

sub make_info($;)
{   my ($self, $slide, $when) = @_;

    my ($title, $time) = ($slide->title, $slide->requiredTime);
    return <<INFO;
slide\t$title ($slide->{number})
time\t$time
start\t$when
INFO
}

1;
