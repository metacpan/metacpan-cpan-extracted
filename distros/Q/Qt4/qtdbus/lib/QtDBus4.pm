#***************************************************************************
#                          QtDBus4.pm  -  QtDBus perl client lib
#                             -------------------
#    begin                : 07-26-2010
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

package QtDBus4::_internal;

use strict;
use warnings;
use QtCore4;
use base qw(Qt::_internal);

$Qt::_internal::customClasses{'Qt::DBusVariant'} = 'Qt::Variant';

sub init {
    foreach my $c ( @{getClassList()}, 'QDBusVariant' ) {
        QtDBus4::_internal->init_class($c);
    }
    foreach my $e ( @{getEnumList()} ) {
        QtDBus4::_internal->init_enum($e);
    }
}

sub normalize_classname {
    my ( $self, $cxxClassName ) = @_;
    $cxxClassName = $self->SUPER::normalize_classname( $cxxClassName );
    return $cxxClassName;
}

package QtDBus4;

use strict;
use warnings;
use QtCore4;

require XSLoader;

our $VERSION = '0.96';

XSLoader::load('QtDBus4', $VERSION);

QtDBus4::_internal::init();

1;

package Qt::DBusReply;

use strict;
use warnings;

sub new {
    my ( $class, $reply ) = @_;
    my $this = bless {}, $class;

    my $error = Qt::DBusError($reply);
    $this->{error} = $error;
    if ( $error->isValid() ) {
        $this->{data} = Qt::Variant();
        return $this;
    }

    my $arguments = $reply->arguments();
    if ( ref $arguments eq 'ARRAY' && scalar @{$arguments} >= 1 ) {
        $this->{data} = $arguments->[0];
        return $this;
    }

    # This only gets called if the 2 previous ifs weren't
    $this->{error} = Qt::DBusError( Qt::DBusError::InvalidSignature(),
                                     'Unexpected reply signature' );
    $this->{data} = Qt::Variant();
    return $this;
}

sub isValid {
    my ( $this ) = @_;
    return !$this->{error}->isValid();
}

sub value() {
    my ( $this ) = @_;
    return $this->{data}->value();
}

sub error() {
    my ( $this ) = @_;
    return $this->{error};
}

# Create the Qt::DBusReply() constructor
Qt::_internal::installSub('Qt::DBusReply', sub { Qt::DBusReply->new(@_) });

1;

package Qt::DBusVariant;

use strict;
use warnings;

sub NEW {
    my ( $class, $value ) = @_;
    if ( ref $value eq ' Qt::Variant' ) {
        $class->SUPER::NEW( $value );
    }
    else {
        $class->SUPER::NEW( $value );
    }
}

1;

