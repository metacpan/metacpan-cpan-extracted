package QListBox;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QFont;
require QPixmap;
require QTableView;

@ISA = qw(DynaLoader QTableView);

$VERSION = '0.01';
bootstrap QListBox $VERSION;


package QListBoxItem;

require QPixmap;


package QListBoxPixmap;

use strict;
use vars qw(@ISA);

@ISA = qw(QListBoxItem);


package QListBoxText;

use strict;
use vars qw(@ISA);

@ISA = qw(QListBoxItem);

1;
__END__

=head1 NAME

QListBox - Interface to the Qt QListBox, QListBoxItem, QListBoxPixmap and QListBoxText classes

=head1 SYNOPSIS

=head2 QListBox

C<use QListBox;>

Inherits QTableView.

=head2 Member functions

new,
autoBottomScrollBar,
autoScroll,
autoScrollBar,
autoUpdate,
bottomScrollBar,
centerCurrentItem,
changeItem,
clear,
count,
currentItem,
dragSelect,
insertItem,
insertStrList,
inSort,
itemHeight,
maxItemWidth,
numItemsVisible,
pixmap,
removeItem,
scrollBar,
setAutoBottomScrollBar,
setAutoScroll,
setAutoScrollBar,
setAutoUpdate,
setBottomScrollBar,
setCurrentItem,
setDragSelect,
setScrollBar,
setSmoothScrolling,
setTopItem,
smoothScrolling,
text,
topItem

=head2 QListBoxItem

Requires QPixmap.

=head2 Member functions

height,
pixmap,
text,
width

=head2 QListBoxPixmap

Inherits QListBoxItem

=head2 Member functions

new

=head2 QListBoxText

Inherits QListBoxItem

=head2 Member functions

new

=head1 DESCRIPTION

What you see is what you get.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
