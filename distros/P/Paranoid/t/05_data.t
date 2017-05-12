#!/usr/bin/perl -T

use Test::More tests => 30;
use Paranoid;
use Paranoid::Debug;
use Paranoid::Data;
use Socket;

use strict;
use warnings;

psecureEnv();

my $sScalar = 'foo';
my @sArray  = qw( one two three four);
my %sHash   = (
    a => 'A Value',
    b => 'B Value',
    c => 'C Value',
    );
my ( $tScalar, @tArray, %tHash, $rv );

# Simple one-level copies
$rv = deepCopy( $sScalar, $tScalar );
is( $rv,      1,     'deepCopy scalar ref 1' );
is( $tScalar, 'foo', 'deepCopy scalar ref 2' );
$rv = deepCopy( @sArray, @tArray );
is( $rv,        4,       'deepCopy array ref 1' );
is( $tArray[2], 'three', 'deepCopy array ref 2' );
$rv = deepCopy( %sHash, %tHash );
is( $rv,       3,         'deepCopy hash ref 1' );
is( $tHash{c}, 'C Value', 'deepCopy hash ref 2' );

# Simple two-level copies
@sArray = ( qw( one two ), [qw( subone subtwo subtree )], qw( three four ), );
%sHash = (
    a => 'A Value',
    b => {
        Key   => 'b',
        Value => 'Hash Ref',
        },
    c => 'C Value',
    );
$rv = deepCopy( @sArray, @tArray );
is( $rv,           8,        'deepCopy array ref 3' );
is( $tArray[2][1], 'subtwo', 'deepCopy array ref 4' );
$rv = deepCopy( %sHash, %tHash );
is( $rv,              5,          'deepCopy hash ref 3' );
is( $tHash{b}{Value}, 'Hash Ref', 'deepCopy hash ref 4' );

# More complex structures
$sHash{d} = {
    Key   => 'd',
    Value => [@sArray],
    };
$sArray[3] = $sHash{b};
$rv = deepCopy( @sArray, @tArray );
is( $rv,             10,  'deepCopy array ref 5' );
is( $tArray[3]{Key}, 'b', 'deepCopy array ref 6' );
$rv = deepCopy( %sHash, %tHash );
is( $rv,                    16,       'deepCopy hash ref 5' );
is( $tHash{d}{Value}[2][1], 'subtwo', 'deepCopy hash ref 6' );

# Expected failures
ok( !eval 'deepCopy(\%sHash, \@tArray)', 'deepCopy fail 1' );
$sArray[2][3] = $sHash{d};
$rv = deepCopy( @sArray, @tArray );
is( $rv, 0, 'deepCopy fail 3' );

@sArray = @tArray = ();
ok( deepCmp( @sArray, @tArray ), 'deepCmp array 1' );
@sArray = @tArray = ( qw(one two three four), undef, qw(six) );
ok( deepCmp( @sArray, @tArray ), 'deepCmp array 2' );
$tArray[4] = 'five';
ok( !deepCmp( @sArray, @tArray ), 'deepCmp array 3' );
$sArray[2] = 3;
ok( !deepCmp( @sArray, @tArray ), 'deepCmp array 4' );

$tArray[4] = undef;
$sArray[2] = 'three';
$sArray[6] = [qw(foo bar)];
$tArray[6] = [qw(foo bar)];
ok( deepCmp( @sArray, @tArray ), 'deepCmp array 5' );
$sArray[6][1] = 'roo';
ok( !deepCmp( @sArray, @tArray ), 'deepCmp array 6' );
$sArray[6] = $tArray[6];
ok( deepCmp( @sArray, @tArray ), 'deepCmp array 7' );
$sArray[6] = '';
ok( !deepCmp( @sArray, @tArray ), 'deepCmp array 8' );

$sArray[6] = { one => 'two', three => 'four' };
ok( !deepCmp( @sArray, @tArray ), 'deepCmp array 9' );
$tArray[6] = { one => 'two', three => 'four' };
ok( deepCmp( @sArray, @tArray ), 'deepCmp array 10' );

#PDEBUG = 20;

%sHash = (
    one   => 1,
    two   => [qw(foo bar)],
    three => {
        foo => 'bar',
        bar => 'roo',
        },
    four => undef,
    );
%tHash = (
    one   => 1,
    two   => [qw(foo bar)],
    three => {
        foo => 'bar',
        bar => 'roo',
        },
    four => undef,
    );
ok( deepCmp( %sHash, %tHash ), 'deepCmp hash 1' );
$tHash{three}{help} = 'me';
ok( !deepCmp( %sHash, %tHash ), 'deepCmp hash 2' );
$sHash{three}{test} = {%tHash};
deepCopy( %sHash, %tHash );
ok( deepCmp( %sHash, %tHash ), 'deepCmp hash 3' );
$tHash{three}{test}{three}{foo} = undef;
ok( !deepCmp( %sHash, %tHash ), 'deepCmp hash 4' );
