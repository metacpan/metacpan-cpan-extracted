# ArithmeticColumnFixture.pm
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Martin Busik <martin.busik@busik.de>

package Test::C2FIT::eg::Calculator;
use base 'Test::C2FIT::ColumnFixture';
use Test::C2FIT::ScientificDouble;
use strict;

sub new {
    my $pkg   = shift;
    my $types = {
        x => 'Test::C2FIT::ScientificDoubleTypeAdapter',
        y => 'Test::C2FIT::ScientificDoubleTypeAdapter',
        z => 'Test::C2FIT::ScientificDoubleTypeAdapter',
        t => 'Test::C2FIT::ScientificDoubleTypeAdapter',
    };
    return bless $pkg->SUPER::new(
        volts               => 0.0,
        key                 => undef,
        methodColumnTypeMap => $types
    ), $pkg;
}

{

    package Test::C2FIT::eg::Calculator::HP35;
    no strict;

    @r = ( 0.0, 0.0, 0.0, 0.0 );
    $s = 0.0;

    sub PI { 3.1415926535897932384626433832795; }

    $dispatch = {
        enter => sub { _push_void() },
        '+'   => sub { _push( _pop() + _pop() ) },
        '*'   => sub { _push( _pop() * _pop() ) },
        '-'   => sub { my $t = _pop(); _push( _pop() - $t ) },
        '/'   => sub { my $t = _pop(); _push( _pop() / $t ) },
        'x^y' => sub { _push( exp( log( _pop() ) * _pop() ) ) },
        'clx' => sub { $r[0] = 0.0 },
        'clr' => sub { @r = ( 0.0, 0.0, 0.0, 0.0 ) },
        'chs'  => sub { $r[0] = -$r[0] },
        'ch s' => sub { $r[0] = -$r[0] },
        'x<>y' => sub { my $t = $r[0]; $r[0] = $r[1]; $r[1] = $t },
        'r!' => sub { $r[3] = _pop() },
        'sto' => sub { $s = $r[0] },
        'rcl'  => sub { _push($s) },
        'sqrt' => sub { _push( sqrt( _pop() ) ) },
        'ln'   => sub { _push( log( _pop() ) ) },
        'sin'  => sub { _push( sin( _pop() / 180 * PI ) ) },
        'cos'  => sub { _push( cos( _pop() / 180 * PI ) ) },
        'tan'  => sub { _push( tan( _pop() / 180 * PI ) ) }
    };

    sub key($) {
        my $key = shift;

        if ( numeric($key) ) {
            _push($key);
        }
        else {
            my $sub = $dispatch->{$key};
            die "can't do key: $key\n" unless ref($sub);

            $sub->($key);
        }
    }

    sub numeric($) {
        my $key = shift;
        return ( $key =~ /^-?\d/ ) ? 1 : undef;
    }

    sub _push_void() {
        for ( my $i = scalar(@r) - 1 ; $i > 0 ; $i-- ) {
            $r[$i] = $r[ $i - 1 ];
        }
    }

    sub _push($) {
        _push_void();
        $r[0] = shift;
    }

    sub _pop() {
        my $v = $r[0];
        for ( my $i = 0 ; $i < scalar(@r) - 1 ; $i++ ) {
            $r[$i] = $r[ $i + 1 ];
        }
        return $v;
    }

    1;
};

sub points() {
    return "false";
}

sub flash() {
    return "false";
}

sub watts() {
    return 1 / 2;
}

sub reset() {
    my $self = shift;
    $self->{key} = undef;
}

sub execute() {
    my $self = shift;
    if ( defined( $self->{key} ) ) {
        Test::C2FIT::eg::Calculator::HP35::key( $self->{key} );
    }
}

sub x() {
    return Test::C2FIT::ScientificDouble->new(
        $Test::C2FIT::eg::Calculator::HP35::r[0] );
}

sub y() {
    return Test::C2FIT::ScientificDouble->new(
        $Test::C2FIT::eg::Calculator::HP35::r[1] );
}

sub z() {
    return Test::C2FIT::ScientificDouble->new(
        $Test::C2FIT::eg::Calculator::HP35::r[2] );
}

sub t() {
    return Test::C2FIT::ScientificDouble->new(
        $Test::C2FIT::eg::Calculator::HP35::r[3] );
}

1;
