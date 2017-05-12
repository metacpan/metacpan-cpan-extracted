package QTabDialog;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QDialog;

@ISA = qw(DynaLoader QDialog);

$VERSION = '0.01';
bootstrap QTabDialog $VERSION;

1;
__END__

=head1 NAME

QTabDialog - Interface to the Qt QTabDialog class

=head1 SYNOPSIS

C<use QTabDialog;>

Inherits QDialog.

=head2 Member functions

new,
addTab,
hasApplyButton,
hasCancelButton,
hasDefaultButton,
isTabEnabled,
setApplyButton,
setCancelButton,
setDefaultButton,
setTabEnabled

=head1 DESCRIPTION

What you see is what you get.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
