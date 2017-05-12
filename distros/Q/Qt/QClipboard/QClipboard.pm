package QClipboard;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QObject;
require QPixmap;

@ISA = qw(DynaLoader QObject);

$VERSION = '0.02';
bootstrap QClipboard $VERSION;

1;
__END__

=head1 NAME

QClipboard - Interface to the Qt QClipboard class

=head1 SYNOPSIS

C<use QClipboard;>

Inherits QObject.

Requires QPixmap.

=head2 Member functions

clear,
pixmap,
setPixmap,
setText,
text

=head1 DESCRIPTION

What you see is what you get.

=head1 SEE ALSO

QClipboard(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
