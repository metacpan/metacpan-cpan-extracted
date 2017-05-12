package QMenuBar;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QFrame;
require QMenuData;

@ISA = qw(DynaLoader QFrame QMenuData);

$VERSION = '0.01';
bootstrap QMenuBar $VERSION;

1;
__END__

=head1 NAME

QMenuBar - Interface to the Qt QMenuBar class

=head1 SYNOPSIS

C<use QMenuBar;>

Inherits QFrame and QMenuData.

=head2 Member functions

new

=head1 DESCRIPTION

What you see is what you get.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
