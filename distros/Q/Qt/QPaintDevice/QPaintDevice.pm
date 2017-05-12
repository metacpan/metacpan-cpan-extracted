package QPaintDevice;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require QGlobal;

@ISA = qw(Exporter DynaLoader Qt::Hash);
@EXPORT = qw(%PDT %PDF &bitBlt);

$VERSION = '0.03';
bootstrap QPaintDevice $VERSION;

1;
__END__

=head1 NAME

QPaintDevice - Interface to the Qt QPaintDevice class

=head1 SYNOPSIS

C<use QPaintDevice;>

=head2 Member functions

devType,
isExtDev,
paintingActive

=head1 DESCRIPTION

A very strange class.

=head1 EXPORTED

The C<%PDT> and C<%PDF> hashes are exported into the user's namespace.
They contain the values of the PD[FT]_* constants.

bitBlt() is also exported, but in a strange twist of Perlian fate,
it can be called as a member-function.

    $widget->bitBlt(dx, dy, pixmap, sx, sy, sw, sh);

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
