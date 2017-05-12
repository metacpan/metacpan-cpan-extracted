#***************************************************************************
#                          QtTest4.pm  -  QtTest perl client lib
#                             -------------------
#    begin                : 07-12-2009
#    copyright            : (C) 2009 by Chris Burel
#    email                : chrisburel@gmail.com
# ***************************************************************************

#***************************************************************************
# *                                                                         *
# *   This program is free software; you can redistribute it and/or modify  *
# *   it under the terms of the GNU General Public License as published by  *
# *   the Free Software Foundation; either version 2 of the License, or     *
# *   (at your option) any later version.                                   *
# *                                                                         *
# ***************************************************************************

package QtTest4::_internal;

use strict;
use warnings;
use QtCore4;
use base qw(Qt::_internal);

sub init {
    @Qt::_internal::vectorTypes{qw(Qt::SignalSpy Qt::TestEventList)} = undef;
    foreach my $c ( @{getClassList()} ) {
        QtTest4::_internal->init_class($c);
    }
    foreach my $e ( @{getEnumList()} ) {
        QtTest4::_internal->init_enum($e);
    }
}

package QtTest4;

use strict;
use warnings;
use QtCore4;

require XSLoader;

our $VERSION = '0.96';

QtCore4::loadModule('QtTest4', $VERSION);

QtTest4::_internal::init();

use Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw( QCOMPARE QVERIFY QTEST_MAIN );

sub QCOMPARE {
}

sub QTEST_MAIN {
    my ($class) = @_;
    my $classPm = $class;
    $classPm =~ s/::/\//g;
    $classPm .= '.pm';
    require $classPm;
    $class->import();
    my $app = Qt::Application(\@ARGV);
    no strict 'refs';
    my $test = &$class();
    use strict;
    unshift @ARGV, $0;
    return Qt::Test::qExec($test, scalar @ARGV, \@ARGV);
}

sub QVERIFY {
    my ($statement, $description) = @_;
    return Qt::Test::qVerify(
        $statement,
        '',
        $description,
        (caller(1))[1],
        (caller(1))[2]
    );
}

package Qt::SignalSpy;

sub EXTEND {
}

package Qt::SignalSpy::_overload;

use overload
    '==' => \&op_equality;

package Qt::TestEventList;

sub EXTEND {
}

package Qt::TestEventList::_overload;

use overload
    '==' => \&op_equality;

1;
