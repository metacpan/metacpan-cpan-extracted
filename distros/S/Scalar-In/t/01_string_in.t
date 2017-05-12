#!perl -T

use strict;
use warnings;
use overload q{""} => sub { 'A' };

use Test::More tests => 33;
use Test::NoWarnings;

BEGIN {
    use_ok('Scalar::In');
}

my @undef  = ( undef );
my @string = qw( A );
my %string = ( A => undef );
my $object = bless {}, __PACKAGE__;
my @object = ( $object );

note 'Scalar';
ok
    string_in( undef, undef ),
    'undef true';
ok
    string_in( undef, undef ),
    'undef true';
ok
    ! string_in( undef, 'A' ),
    'undef left';
ok
    ! string_in( 'A', undef ),
    'undef right';
ok
    string_in( 'A', 'A' ),
    'string true';
ok
    string_in( 'A', qr{ \A [A] \z }xms ),
    'string regex true';
ok
    ! string_in( 'A', 'AA' ),
    'string false';
ok
    ! string_in( 'A', qr{ \A [A]{2} \z }xms ),
    'string regex false';
ok
    string_in( 'ABCDEFG', sub { 0 == index shift, 'ABC' } ),
    'string code true';
ok
    string_in( $object, 'A' ),
    'object left true';
ok
    string_in( 'A', $object ),
    'object right true';

note 'Array reference';
ok
    string_in( \@undef, \@undef ),
    'undef true';
ok
    ! string_in( \@undef, \@string ),
    'undef left';
ok
    ! string_in( \@string, \@undef ),
    'undef right';
ok
    string_in( \@string, \@string ),
    'string true';
ok
    string_in( \@string, [ qr{ \A [A] \z }xms ] ),
    'string regex true';
ok
    ! string_in( \@string, [ 'AA' ] ),
    'string false';
ok
    ! string_in( \@string, [ qr{ \A [A]{2} \z }xms ] ),
    'string regex false';

note 'Array';
ok
    string_in( @undef, @undef ),
    'undef true';
ok
    ! string_in( @undef, @{[ 'A' .. 'C' ]} ),
    'undef left';
ok
    ! string_in( @string, @undef ),
    'undef right';
ok
    string_in( @string, @{[ 'A' .. 'C' ]} ),
    'string true';
ok
    string_in( @string, @{[ qr{ \A [ABC] \z }xms ]} ),
    'string regex true';
ok
    ! string_in( @string, @{[ 'B' .. 'C' ]} ),
    'string false';
ok
    ! string_in( @string, @{[ qr{ \A [BC] \z }xms ]} ),
    'string regex false';

note 'Hash reference';
ok
    ! string_in( undef, \%string ),
    'undef left';
ok
    string_in( \%string, \%string ),
    'string true';
ok
    ! string_in( \%string, { B => undef } ),
    'string false';

note 'Hash';
ok
    ! string_in( undef, %string ),
    'undef left';
ok
    string_in( %string, %{{ A => undef, B => undef, C => undef }} ),
    'string true';
ok
    ! string_in( %string, %{{ B => undef, C => undef }} ),
    'string false';
