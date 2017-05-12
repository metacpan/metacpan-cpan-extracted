package QFrame;

use strict;
use vars qw($VERSION @ISA @ANCESTORS @EXPORT);

require Exporter;
require DynaLoader;
require QGlobal;

require QRect;
require QWidget;

@ISA = qw(Exporter DynaLoader QWidget);
@EXPORT = qw(%QFrame);

$VERSION = '0.02';
bootstrap QFrame $VERSION;

1;
__END__

=head1 NAME

QFrame - Interface to the Qt QFrame class

=head1 SYNOPSIS

C<use QFrame;>

Inherits QWidget.

Requires QRect.

=head2 Member functions

new,
contentsRect,
frameRect,
frameShadow,
frameShape,
frameStyle,
frameWidth,
lineShapesOk,
lineWidth,
midLineWidth,
setFrameStyle,
setLineWidth,
setMidLineWidth

=head1 DESCRIPTION

As direct an interface as humanly possible.

=head1 EXPORTED

Exports C<%QFrame> into the user's namespace. It contains all the constants
accessed through QFrame:: in C++

=head1 CAVEATS

I don't like C<%QFrame>, and it wouldn't take much for me to move them all
into the QFrame namespace and be done with it.

=head1 SEE ALSO

QFrame(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
