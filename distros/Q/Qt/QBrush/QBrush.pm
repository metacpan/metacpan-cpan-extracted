package QBrush;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require QGlobal;

require QColor;
require QPixmap;

@ISA = qw(Exporter DynaLoader Qt::Hash);
@EXPORT = qw(%BrushStyle);

$VERSION = '0.02';
bootstrap QBrush $VERSION;

1;
__END__

=head1 NAME

QBrush - Interface to the Qt QBrush class

=head1 SYNOPSIS

C<use QBrush;>

Requires QColor and QPixmap.

=head2 Member functions

new,
color,
pixmap,
setColor,
setPixmap,
setStyle,
style

=head1 DESCRIPTION

As direct an interface as humanly possible.

=head1 EXPORTED

The C<%BrushStyle> hash is exported into the user's namespace. Since there
is no chance for namespace pollution, all C<%BrushStyle> elements ending in
C<Pattern> have been truncated so as to remove the C<Pattern>.

=head1 SEE ALSO

QBrush(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>

