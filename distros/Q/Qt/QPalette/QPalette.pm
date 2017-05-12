package QPalette;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

@ISA = qw(DynaLoader Qt::Hash);

$VERSION = '0.02';
bootstrap QPalette $VERSION;


package QColorGroup;

use strict;
use vars qw(@ISA);

require QGlobal;

require QColor;

@ISA = qw(Qt::Hash);

1;
__END__

=head1 NAME

QPalette - Interface to the Qt QPalette and QColorGroup classes

=head1 SYNOPSIS

C<use QPalette;>

=head2 QColorGroup

Requires QColor.

=head2 Member functions

new,
background,
base,
dark,
foreground,
light,
mid,
text

=head2 QPalette

=head2 Member functions

new,
active,
copy,
disabled,
normal,
setActive,
setDisabled,
setNormal,
serialNumber

=head1 DESCRIPTION

What you see is what you get.

=head1 SEE ALSO

QPalette(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
