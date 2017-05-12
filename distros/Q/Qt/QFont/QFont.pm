package QFont;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require QGlobal;

@ISA = qw(Exporter DynaLoader Qt::Hash);
@EXPORT = qw(%StyleHint %Weight %CharSet);

$VERSION = '0.03';
bootstrap QFont $VERSION;

1;
__END__

=head1 NAME

QFont - Interface to the Qt QFont class

=head1 SYNOPSIS

C<use QFont;>

=head2 Member functions

new,
bold,
charSet,
defaultFont,
exactMatch,
family,
fixedPitch,
insertSubstitution,
italic,
pointSize,
rawMode,
removeSubstitution,
setBold,
setCharSet,
setDefaultFont,
setFamily,
setFixedPitch,
setItalic,
setPointSize,
setRawMode,
setStrikeOut,
setStyleHint,
setUnderline,
setWeight,
strikeOut,
styleHint,
substitute,
underline,
weight

=head1 DESCRIPTION

What you see is what you get.

=head1 EXPORTED

Three hashes, C<%StyleHint>, C<%Weight>, and C<%CharSet>, are exported into
the user's namespace. They correspond to the three enums in the QFont
class, and, if combined, contain all the constant values that were
accessed through QFont:: in C++.

To refresh your memory without requiring you to read F<qfont.h>, 
C<%StyleHint> elements are font-names S<(Helvetica, Times, etc)>,
C<%Weight> elements are the character's darkness S<(Light, Bold, etc)>,
C<%CharSet> should be obvious enough to anyone who needs it.

=head1 SEE ALSO

QFont(3pl)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
