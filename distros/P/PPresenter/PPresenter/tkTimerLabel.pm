# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::tkTimerLabel;

use strict;
use Tk::Derived;
use Tk::Label;
use base qw(Tk::Derived Tk::Label);

Construct Tk::Widget 'TimerLabel';

sub Populate
{   my ($w, $args) = @_;

    $w->SUPER::Populate($args);

    $w->ConfigSpecs
    ( -maxValue   => [ qw/PASSIVE maxValue MaxValue/,       300 ]
    , -value      => [ qw/PASSIVE value Value/,               0 ]
    , -setValue   => [ qw/METHOD setValue SetValue/,          0 ]
    , -step       => [ qw/METHOD step Step/,                  0 ]
    , -colorScale => [ qw/PASSIVE colorScale ColorScale/, undef ]
            # [qw/white 0.8 green 1.2 red/]
    );
}

sub makeTime($)
{   my $secs = int $_[1];
    my $mins = int($secs/60);
    sprintf '%3d:%02d', $mins, $secs-60*$mins;
}

sub makeColor($$)
{   my ($w, $value, $max) = @_;

    my $colors = $w->cget(-colorScale);
    return 'white' unless defined $colors;
    return $colors->[0] unless defined $max && $max != 0;

    my $percentage = $value/$max;

    @_ = @$colors;
    shift, shift until(!defined $_[1] || $_[1] > $percentage);
    return $_[0];
}

sub step($)
{   my ($w, $step) = @_;
    my $value = $w->cget('-value') || 0;
    $w->setValue($value+$step);
}

sub setValue($)
{   my ($w, $value) = @_;

    $w->configure
    ( -text       => $w->makeTime($value),
    , -background => $w->makeColor($value, $w->cget('-maxValue'))
    , -value      => $value
    );
}
