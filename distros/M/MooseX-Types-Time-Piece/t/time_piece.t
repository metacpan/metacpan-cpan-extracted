#!perl -T

use strict;
use warnings;

use Test::More tests => 18;
use Test::Fatal;

use Time::HiRes ();
use Time::Piece;
use Time::Seconds;

# ---------------------------
# Test Classes
{
    package Implicit;
    use Moose;
    use MooseX::Types::Time::Piece;
    has 'time' => ( is => 'rw', isa => 'Time::Piece', coerce => 1 );
    has 'duration' => ( is => 'rw', isa => 'Time::Seconds', coerce => 1 );
}
{
    package Declared;
    use Moose;
    use MooseX::Types::Time::Piece qw( Time Duration );
    has 'time' => ( is => 'rw', isa => Time, coerce => 1 );
    has 'duration' => ( is  => 'rw', isa => Duration, coerce => 1 );
}

# ---------------------------
# Tests

for my $class ('Implicit', 'Declared') {
    my $exp;
    my $got = $class->new;

    # -----------------------
    # coerce from Num
    $exp = localtime;
    $got->time( $exp->epoch );
    is( $got->time, $exp, 'int coercion' );

    my $hires = Time::HiRes::time();
    $exp = localtime($hires);
    $got->time($hires);
    is( $got->time, $exp, 'num coercion' );

    # -----------------------
    # coerce from Str
    $exp = localtime;
    $got->time( $exp->datetime );
    is( $got->time, $exp, 'str coercion' );

    like(
        exception { $got->time("$exp") },
        qr/^Error parsing time '$exp' with format '.+'/,
        'invalid str coercion'
    );

    # -----------------------
    # coerce from ArrayRef
    my $format = '%Y-%m-%d %H:%M:%S';

    $exp = localtime;
    $got->time( [ $exp->strftime($format), $format ] );
    is( $got->time, $exp, 'arrayref coercion' );

    $exp = localtime;
    $got->time( [ $exp->strftime($format), $format, 'these args', 'should be ignored' ] );
    is( $got->time, $exp, 'arrayref coercion with extra values' );

    # Time::Piece->strptime without format arg is broken
    # as it doesn't accept timezones other than GMT
    #$exp = localtime;
    #$got->time( [ $exp->strftime ] );
    #is( $got->time, $exp, 'arrayref coercion with single value' );

    like(
        exception { $got->time( [ "$exp", $format ] ) },
        qr/^Error parsing time '$exp' with format '$format'/,
        'invalid arrayref coercion'
    );

    # -----------------------
    # Duration
    $got->duration( 2.5 );
    is( $got->duration->seconds, 2.5, 'duration coercion' );

    $got->duration(-1);
    is( $got->duration->seconds, -1, 'negative duration coercion' );
}
