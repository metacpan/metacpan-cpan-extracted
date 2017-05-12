package QtCore4::debug;

use strict;
use warnings;
use QtCore4;

our $VERSION = 0.60;

our %channel = (
    'ambiguous' => 0x01,
    'autoload' => 0x02,
    'calls' => 0x04,
    'gc' => 0x08,
    'virtual' => 0x10,
    'verbose' => 0x20,
    'signals' => 0x40,
    'slots' => 0x80,
    'all' => 0xff
);

sub dumpMetaMethods {
    my ( $object ) = @_;

    my @return;

    # Did we get an object in, or just a class name?
    my $className = ref $object ? ref $object : $object;
    $className =~ s/^ *//;
    my $meta = Qt::_internal::getMetaObject( $className );

    if ( $meta->methodCount() ) {
        push @return, join '', 'Methods for ', $meta->className();
    }
    else {
        push @return, join '', 'No methods for ', $meta->className();
    }
    foreach my $index ( 0..$meta->methodCount()-1 ) {
        my $metaMethod = $meta->method($index);
        push @return, join ' ', grep{ /./ } ($metaMethod->typeName(), $metaMethod->signature());
    }

    if ( $meta->classInfoCount() ) {
        push @return, join '', 'Class info for ', $meta->className();
    }
    else {
        push @return, join '', 'No class info for ', $meta->className();
    }
    foreach my $index ( 0..$meta->classInfoCount()-1 ) {
        my $classInfo = $meta->classInfo($index);
        push @return, join '', '\'', $classInfo->name, '\' => \'', $classInfo->value;
    }
    return @return;
}

sub import {
    shift;
    my $db = (@_) ? 0x00 : 0x01;
    my $usage = 0;
    for my $ch(@_) {
        if( exists $channel{$ch}) {
             $db |= $channel{$ch};
        } else {
             warn "Unknown debugging channel: $ch\n";
             $usage++;
        }
    }
    Qt::_internal::setDebug($db);    
    print "Available channels: \n\t".
          join("\n\t", sort keys %channel).
          "\n" if $usage;
}

sub unimport {
    Qt::_internal::setDebug(0);    
}

1;
