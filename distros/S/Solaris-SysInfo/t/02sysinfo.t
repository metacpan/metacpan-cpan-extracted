#!/usr/bin/perl -w

use strict;

use Test::More tests => 18;

use Solaris::SysInfo qw( sysinfo SI_ISALIST );

use POSIX qw( uname EINVAL );

my @uname = uname();

my $ret;

# The first 5 sysinfo() entries should match the five results from uname()

$ret = sysinfo( 1 );
ok( defined $ret, 'defined $ret for 1' );
is( $ret, $uname[0], 'sysname' );

$ret = sysinfo( 2 );
ok( defined $ret, 'defined $ret for 2' );
is( $ret, $uname[1], 'sysname' );

$ret = sysinfo( 3 );
ok( defined $ret, 'defined $ret for 3' );
is( $ret, $uname[2], 'sysname' );

$ret = sysinfo( 4 );
ok( defined $ret, 'defined $ret for 4' );
is( $ret, $uname[3], 'sysname' );

$ret = sysinfo( 5 );
ok( defined $ret, 'defined $ret for 5' );
is( $ret, $uname[4], 'sysname' );

$ret = sysinfo( SI_ISALIST );
ok( defined $ret, 'defined $ret' );

my @list = split( m/ /, $ret );
ok( scalar @list > 1, '$ret contains more than one word' );

# Check it works just as well with strings-that-look-like-numbers
$ret = sysinfo( "514" );
ok( defined $ret, 'defined $ret with string-as-number' );

# Solaris doesn't define 100
$ret = sysinfo( 100 );
my $errno = $!+0;
ok( !defined $ret,    'not defined $ret with invalid number' );
ok( $errno == EINVAL, '$! == EINVAL with invalid number' );

my $warning;

{
   local $SIG{__WARN__} = sub { $warning = shift };
   $ret = sysinfo( "Hello" );
   $errno = $!+0;
}

ok( !defined $ret,    'not defined $ret with invalid number' );
ok( $errno == EINVAL, '$! == EINVAL with invalid number' );
like( $warning, qr/\bisn't numeric\b/, 'appropriate warning with invalid number' );
