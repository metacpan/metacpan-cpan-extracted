package QTimer;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QObject;

@ISA = qw(DynaLoader QObject);

$VERSION = '0.01';
bootstrap QTimer $VERSION;

1;
__END__

=head1 NAME

QTimer - Interface to the Qt QTimer class

=head1 SYNOPSIS

C<use QTimer;>

Inherits QObject.

=head2 Member functions

new,
changeInterval,
isActive,
singleShot,
start,
stop

=head1 DESCRIPTION

What you see is what you get.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
