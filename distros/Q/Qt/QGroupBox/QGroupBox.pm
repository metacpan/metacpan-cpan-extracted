package QGroupBox;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use QGlobal qw(%Align $SingleLine $DontClip $ExpandTabs $ShowPrefix $WordBreak
               $GrayText $DontPrint);

require Exporter;
require DynaLoader;

require QFrame;

@ISA = qw(Exporter DynaLoader QFrame);
@EXPORT = qw(%Align $SingleLine $DontClip $ExpandTabs $ShowPrefix $WordBreak
             $GrayText $DontPrint);

$VERSION = '0.02';
bootstrap QGroupBox $VERSION;

1;
__END__

=head1 NAME

QGroupBox - Interface to the Qt QGroupBox class

=head1 SYNOPSIS

C<use QGroupBox;>

Inherits QFrame.

=head2 Member functions

new,
alignment,
setAlignment,
setTitle,
title

=head1 DESCRIPTION

What you see is what you get.

=head1 EXPORTED

The following variables are exported into the user's namespace:

%Align $SingleLine $DontClip $ExpandTabs $ShowPrefix $WordBreak
$GrayText $DontPrint

See L<QPainter(3)> for info

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
