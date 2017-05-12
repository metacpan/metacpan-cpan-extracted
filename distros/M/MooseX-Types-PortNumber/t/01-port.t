#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

{
    package MyClass;
    use Moose;
    use MooseX::Types::PortNumber
        qw/PortNumber PortWellKnow PortRegistered PortPrivate/;
    use namespace::autoclean;

    has port => ( isa => PortNumber,     is => 'ro' );
    has well => ( isa => PortWellKnow,   is => 'ro' );
    has reg  => ( isa => PortRegistered, is => 'ro' );
    has priv => ( isa => PortPrivate,    is => 'ro' );

    __PACKAGE__->meta->make_immutable;
}

lives_ok { MyClass->new( port => 100 ) } '100 is an port number';
throws_ok { MyClass->new( port => -1 ) }
qr/Ports are those from 0 through 65535/,
    'Throws as "-1" is not a valid port';

lives_ok { MyClass->new( well => 100 ) } '100 is an well port number';
throws_ok { MyClass->new( well => 5000 ) }
qr/The Well Known Ports are those from 0 through 1023./,
    'Throws as "5000" is not a valid well port number.';

lives_ok { MyClass->new( reg => 1025 ) } '1025 is an registered port number';
throws_ok { MyClass->new( reg => 5 ) }
qr/are those from/,
    'Throws as "5" is not a valid registered port number.';

lives_ok { MyClass->new( priv => 50000 ) } '50000 is an private port number';
throws_ok { MyClass->new( priv => 1500 ) }
qr/are those from/,
    'Throws as "1500" is not a valid private port number.';

done_testing();
