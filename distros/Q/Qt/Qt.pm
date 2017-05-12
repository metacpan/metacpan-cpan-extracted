package Qt;

use strict;
use vars qw($VERSION @ISA @EXPORT $qApp);
use QGlobal;

require Exporter;
require QApplication;

@ISA = qw(Exporter);
@EXPORT = qw($qApp &qRound);

$VERSION = '0.03';

$qApp = new QApplication;

1;
__END__

=head1 NAME

Qt - A Perl module interface to Qt

=head1 SYNOPSIS

C<use Qt;>

Requires QApplication and QGlobal.

=head1 DESCRIPTION

The Qt module itself only creates a $qApp and exports some QGlobal imports.

This module is not the whole of the Qt interface, though. Each header in
Qt which holds a class is represented by a module with the name of that
class. Classes like QWidget and QApplication are represented by modules
of the same name. QResizeEvent is not a module, but rather is part of
the QEvent module, just as the QResizeEvent class is a part of F<qevent.h>.

Each class header that has been interfaced to Perl has a pod attached which
describes the function interface from Qt.

=head1 EXPORTED

The Qt module exports $qApp and C<&qRound>.

=head1 SEE ALSO

QApplication(3qt), QApplication(3), QGlobal(3)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
