#!/usr/bin/perl -T

use Test::More tests => 146;
use Paranoid;
use Paranoid::Input qw(:all);
use Paranoid::Debug;

use strict;
use warnings;

psecureEnv();

my ( $val, $fh, $f, $l, @lines, $rv, @all );

# Test detainting of valid data
my @tests = (
    [qw(100             number)],       [qw(-0.5            number)],
    [qw(abc             alphabetic)],   [qw(abc123          alphanumeric)],
    [qw(THX1138         alphanumeric)], [qw(acorliss        login)],
    [qw(foo@bar         email)],        [qw(foo.foo@bar.com email)],
    [qw(a-.-a";         nometa)],       [qw(/foo/bar/.foo   filename)],
    [qw(localhost       hostname)],     [qw(7x.com          hostname)],
    [qw(foo.bar-roo.org hostname)],     [qw(127.0.0.1       ipv4addr)],
    [qw(127.0.0.1/8     ipv4netaddr)],  [qw(::1             ipv6addr)],
    [qw(::1/128         ipv6netaddr)],  [qw(fe80::250:56ff:fec0:8/64
                                            ipv6netaddr)],
    );
foreach (@tests) {
    ok( detaint( $$_[0], $$_[1], $val ), "detaint $$_[0] ($$_[1]) 1" );
    is( $val, $$_[0], "$$_[0] ($$_[1]) match 1" );
}

# Repeat test copying results to original scalar
foreach (@tests) {
    $val = $$_[0];
    ok( detaint( $val, $$_[1] ), "detaint $$_[0] ($$_[1]) 2" );
    is( $val, $$_[0], "$$_[0] == $val ($$_[1]) $val match 2" );
}

# Test detainting of invalid data
@tests = (
    [qw(100.00.1        number)],       [qw(aDb97_          alphabetic)],
    [qw(abc-123         alphanumeric)], [qw(1foo            login)],
    [qw(_34@bar.com     email)],        [qw('`!             nometa)],
    [qw(/^/foo          filename)],     [qw(-foo.com        hostname)],
    [qw(foo_bar.org     hostname)],     [qw(294.0.0.1       ipv4addr)],
    [qw(ge00::          ipv6addr)],     [qw(127.0.0.1/48    ipv4netaddr)],
    [qw(fe80::/256      ipv6netaddr)],  [qw(fe80::ac87::    ipv6netaddr)],
    );
foreach (@tests) {
    ok( !detaint( $$_[0], $$_[1], $val ), "detaint $$_[0] ($$_[1])" );
    is( $val, undef, 'value is undef' );
}

# Test detaint of arrays
my @vals;
@tests = qw(100 -0.5);
ok( detaint( @tests, 'number', @vals ), 'detaint array 1' );
is( $vals[0], 100, 'detaint array 2' );
ok( detaint( @tests, 'number' ), 'detaint array 3' );
is( $tests[0], 100, 'detaint array 4' );
push @tests, 'localhost';
ok( !detaint( @tests, 'number', @vals ), 'detaint array 5' );
is( scalar(@vals), 3,     'detaint array 6' );
is( $vals[0],      100,   'detaint array 7' );
is( $vals[2],      undef, 'detaint array 8' );
push @tests, 'localhost';
ok( !detaint( @tests, 'number' ), 'detaint array 9' );
is( scalar(@tests), 4,     'detaint array 10' );
is( $tests[0],      100,   'detaint array 11' );
is( $tests[3],      undef, 'detaint array 12' );

# Test detaint of hashes
my %vals;
my %tests = (
    one => 100,
    two => -0.5,
    );
ok( detaint( %tests, 'number', %vals ), 'detaint hash 1' );
is( $vals{one}, 100, 'detaint hash 2' );
ok( detaint( %tests, 'number' ), 'detaint hash 3' );
is( $tests{one}, 100, 'detaint hash 4' );
$tests{three} = 'localhost';
ok( !detaint( %tests, 'number', %vals ), 'detaint hash 5' );
is( scalar( keys %vals ), 3,     'detaint hash 6' );
is( $vals{one},           100,   'detaint hash 7' );
is( $vals{three},         undef, 'detaint hash 8' );
$tests{four} = 'localhost';
ok( !detaint( %tests, 'number' ), 'detaint hash 9' );
is( scalar( keys %tests ), 4,     'detaint hash 10' );
is( $tests{one},           100,   'detaint hash 11' );
is( $tests{three},         undef, 'detaint hash 12' );
is( $tests{four},          undef, 'detaint hash 13' );

# Test non-existent regex
my $foo = "foo";
ok( !detaint( $foo, 'arg', $val ), 'detaint w/unknown regex' );

# Test regex
ok( detaint( $foo, qr/.o*/si, $val ), 'detaint w/passed regex 1' );
is( $foo, $val, 'detaint w/passed regex 2' );

# Test custom regex
$Paranoid::Input::regexes{tel} = qr/\d{3}-\d{4}/;
$foo = '345-7211';
ok( detaint( $foo, 'tel', $val ), 'detaint 345-7211 tel' );
is( $val, '345-7211', 'strings match' );

# Test stringMatch
my $long = << '__EOF__';
This is a semi-random string of gibberish that merely pretends 
to be a paragraph in search of a meaning.  I only want to 
throw enough content at my poor, pitiful subroutine to verify 
that it actually works.

It probably won't, though, and that's a damned shame.
__EOF__
my @words1 = qw( /semi/ gibberish pitiful /ara/ );
my @words2 = qw( /exa/ /on.f/ );
ok( stringMatch( $long, @words1 ), 'stringMatch (good test)' );
ok( !stringMatch( $long, @words2 ), 'stringMatch (bad test)' );

# Test pchomp
@lines = (
    "This was authored on UNIX.\12",
    "This was authored on Mac.\15",
    "This was authored on PC.\15\12",
    "This was authored in my head.",
    );

# First, scalar tests
my $counter = 0;
foreach (@lines) {
    $l = $_;
    $counter++;
    ($val) = ( $l =~ /^(.+\.)/ );
    pchomp($l);
    is( $val, $l, "pchomp scalar $counter" );
}

# Test arrrays
$val = length join '', @lines;
ok( pchomp(@lines), 'pchomp array 1' );
is( $val - 4, length( join '', @lines ), 'pchomp array 2' );

# Test hashes
my %hash = (
    one   => "This was authored on UNIX.\12",
    two   => "This was authored on Mac.\15",
    three => "This was authored on PC.\15\12",
    four  => "This was authored in my head.",
    );
ok( pchomp(%hash), 'pchomp hash 1' );
is( $val - 4, length( join '', values %hash ), 'pchomp hash 2' );

# Test builtin vars
$_ = "hello!\n";
ok( pchomp(), 'pchomp $_ 1' );
is( length($_), length('hello!'), 'pchomp $_ 2' );

# Test chomp fall-through
{
    local $/;
    $/ = ':';
    my $out = "This was authored on UNIX.\12";
    $rv = pchomp($out);
    ok( $rv == 0, "pchomp fall-through 1" );
    $/  = undef;
    $rv = pchomp($out);
    ok( $rv == 0, "pchomp fall-through 2" );
    $/  = 30;
    $rv = pchomp($out);
    ok( $rv == 0, "pchomp fall-through 3" );
    $/  = ".\12";
    $rv = pchomp($out);
    ok( $rv == 2, "pchomp fall-through 4" );
}

