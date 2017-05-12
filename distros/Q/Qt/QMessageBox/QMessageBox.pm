package QMessageBox;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QDialog;

@ISA = qw(DynaLoader QDialog);

$VERSION = '0.01';
bootstrap QMessageBox $VERSION;

1;
__END__

=head1 NAME

QMessageBox - Interface to the Qt QMessageBox class

=head1 SYNOPSIS

C<use QMessageBox;>

Inherits QDialog.

=head2 Member functions

new,
adjustSize,
buttonText,
message,
query,
setButtonText,
setText,
text

=head1 DESCRIPTION

What you see is what you get.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
