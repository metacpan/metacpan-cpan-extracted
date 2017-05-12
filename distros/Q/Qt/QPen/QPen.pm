package QPen;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require QGlobal;

require QColor;

@ISA = qw(Exporter DynaLoader Qt::Hash);
@EXPORT = qw(%PenStyle);

$VERSION = '0.02';
bootstrap QPen $VERSION;

1;
__END__

=head1 NAME

QPen - Interface to the Qt QPen class

=head1 SYNOPSIS

C<use QPen;>

Requires QColor.

=head2 Member functions

new,
color,
setColor,
setStyle,
setWidth,
style,
width

=head1 DESCRIPTION

Except for the operators, this class is fully implemented.

=head1 EXPORTED

The C<%PenStyle> hash is exported into the user's namespace, and contains
all of the elements from the PenStyle enum defined in F<qpen.h>.

=head1 SEE ALSO

QPen(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
