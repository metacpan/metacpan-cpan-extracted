package QCheckBox;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QButton;

@ISA = qw(DynaLoader QButton);

$VERSION = '0.01';
bootstrap QCheckBox $VERSION;

1;
__END__

=head1 NAME

QCheckBox - Interface to the Qt QCheckBox class

=head1 SYNOPSIS

C<use QCheckBox;>

Inherits QButton.

=head2 Member functions

new,
isChecked,
setChecked

=head1 DESCRIPTION

What you see is what you get.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
