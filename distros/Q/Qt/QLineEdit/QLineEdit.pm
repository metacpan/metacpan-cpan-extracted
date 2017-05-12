package QLineEdit;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QWidget;

@ISA = qw(DynaLoader QWidget);

$VERSION = '0.01';
bootstrap QLineEdit $VERSION;

1;
__END__

=head1 NAME

QLineEdit - Interface to the Qt QLineEdit class

=head1 SYNOPSIS

C<use QLineEdit;>

Inherits QWidget.

=head2 Member functions

new,
deselect,
maxLength,
selectAll,
setMaxLength,
setText,
text

=head1 DESCRIPTION

What you see is what you get.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
