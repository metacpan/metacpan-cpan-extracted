package QFontInfo;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QFont;

@ISA = qw(DynaLoader Qt::Hash);

$VERSION = '0.02';
bootstrap QFontInfo $VERSION;

1;
__END__

=head1 NAME

QFontInfo - Interface to the Qt QFontInfo class

=head1 SYNOPSIS

C<use QFontInfo;>

Requires QFont.

=head2 Member functions

bold,
charSet,
exactMatch,
family,
fixedPitch,
font,
italic,
pointSize,
rawMode,
strikeOut,
styleHint,
underline,
weight

=head1 DESCRIPTION

This class is fully interfaced. WYSIWYG

=head1 SEE ALSO

QFontInfo(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
