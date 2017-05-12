package QSlider;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require QGlobal;

require QRangeControl;
require QWidget;

@ISA = qw(Exporter DynaLoader QWidget QRangeControl);
@EXPORT = qw(%Orientation %TickSetting);

$VERSION = '0.01';
bootstrap QSlider $VERSION;

1;
__END__

=head1 NAME

QSlider - Interface to the Qt QSlider class

=head1 SYNOPSIS

C<use QSlider;>

Inherits QWidget and QRangeControl.

=head2 Member functions

new,
addStep,
orientation,
setOrientation,
setTickmarks,
setTracking,
setValue,
sliderRect,
subtractSteps,
tickInterval,
tickmarks,
tracking

=head1 DESCRIPTION

What you see is what you get.

=head1 EXPORTED

The C<%Orientation> and C<%TickSetting> hashes are exported into the user's
namespace. The elements of C<%Orientation> are C<Horizontal> and C<Vertical>,
and they represent the possible orientations of the slider. The
C<%TickSetting> hash has all the tick setting constants.

=head1 SEE ALSO

qslider(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
