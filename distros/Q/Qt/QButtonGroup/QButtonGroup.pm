package QButtonGroup;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QButton;
require QGroupBox;

@ISA = qw(DynaLoader QGroupBox);

$VERSION = '0.01';
bootstrap QButtonGroup $VERSION;

1;
__END__

=head1 NAME

QButtonGroup - Interface to the Qt QButtonGroup class

=head1 SYNOPSIS

C<use QButtonGroup;>

Inherits QGroupBox.

Requires QButton.

=head2 Member functions

new,
find,
insert,
isExclusive,
remove,
setExclusive

=head1 DESCRIPTION

What you see is what you get.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
