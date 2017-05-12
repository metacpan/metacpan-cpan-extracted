package QMultiLineEdit;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QFont;
require QTableView;

@ISA = qw(DynaLoader QTableView);

$VERSION = '0.01';
bootstrap QMultiLineEdit $VERSION;

1;
__END__

=head1 NAME

QMultiLineEdit - Interface to the Qt QMultiLineEdit class

=head1 SYNOPSIS

C<use QMultiLineEdit;>

Inherits QTableView.

Requires QFont.

=head2 Member functions

new,
append,
atBeginning,
atEnd,
autoUpdate,
clear,
copyText,
cut,
deselect,
getCursorPosition,
insertAt,
insertLine,
isOverwriteMode,
isReadOnly,
numLines,
paste,
removeLine,
selectAll,
setAutoUpdate,
setCursorPosition,
setOverwriteMode,
setReadOnly,
setText,
text,
textLine

=head1 DESCRIPTION

What you see is what you get.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
