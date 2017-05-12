package QWindow;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QWidget;

@ISA = qw(DynaLoader QWidget);

$VERSION = '0.02';
bootstrap QWindow $VERSION;

1;
__END__

=head1 NAME

QWindow - Interface to the Qt QWindow class

=head1 SYNOPSIS

C<use QWindow;>

Inherits QWidget.

=head2 Member functions

new

=head1 DESCRIPTION

Not much here.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
