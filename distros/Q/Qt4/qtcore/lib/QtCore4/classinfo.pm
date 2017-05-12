package QtCore4::classinfo;
#
# Proposed usage:
#
# use QtCore4::classinfo key => value;
#

use strict;
use warnings;
use Carp;
use QtCore4;

our $VERSION = 0.60;

sub import {
    no strict 'refs';
    my $self = shift;
    croak "Odd number of arguments in classinfo declaration" if @_%2;
    my $caller = $self eq 'QtCore4::classinfo' ? (caller)[0] : $self;
    my(%classinfos) = @_;
    my $meta = \%{ $caller . '::META' };

    # See QtCore4::slots for explanation of this sub
    *{ "${caller}::metaObject" } = sub {
        return Qt::_internal::getMetaObject($caller);
    } unless defined &{ "${caller}::metaObject" };

    Qt::_internal::installqt_metacall( $caller ) unless defined &{$caller."::qt_metacall"};

    foreach my $key ( keys %classinfos ) {
        my $value = $classinfos{$key};

        my $classinfo = {
            $key => $value
        };

        push @{$meta->{classinfos}}, $classinfo;
    }
}

1;
