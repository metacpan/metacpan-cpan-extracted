#***************************************************************************
#                          Qsci.pm  -  Qsci perl client lib
#                             -------------------
#    begin                : 11-14-2010
#    copyright            : (C) 2010 by Chris Burel
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

package Qsci::_internal;

use strict;
use warnings;
use QtCore4;
use base qw(Qt::_internal);

sub init {
    foreach my $c ( @{getClassList()} ) {
        Qsci::_internal->init_class($c);
    }
    foreach my $e ( @{getEnumList()} ) {
        Qsci::_internal->init_enum($e);
    }
}

sub normalize_classname {
    my ( $self, $cxxClassName ) = @_;
    $cxxClassName = $self->SUPER::normalize_classname( $cxxClassName );
    return $cxxClassName;
}

package Qsci;

use strict;
use warnings;
use QtCore4;

require XSLoader;

our $VERSION = '0.96';

QtCore4::loadModule('Qsci', $VERSION);

Qsci::_internal::init();

1;
