package QTableView;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QFrame;

@ISA = qw(DynaLoader QFrame);

$VERSION = '0.01';
bootstrap QTableView $VERSION;

1;
__END__

=head1 NAME

QTableView - Interface to the Qt QTableView class

=head1 SYNOPSIS

C<use QTableView;>

Inherits QFrame.

=head1 DESCRIPTION

Empty.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
