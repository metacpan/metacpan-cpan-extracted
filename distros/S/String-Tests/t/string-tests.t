#!perl -T
use strict;
use Test::More tests => 25;
use Test::Exception;

use_ok 'String::Tests';

sub section { print STDOUT "# $_[0]\n" } # diag() prints to STDERR :(

########################################################################
section( 'LIST - REGEXP TESTS - example strict password validation' );

my $regexps = [ # example of strict password validation
    qr/^[\w[:punct:]]{8,16}\z/, # character white list
    qr/[A-Z]/, # force 1 upper case
    qr/[a-z]/, # force 1 lower case
    qr/\d/, # force 1 digit
    qr/[[:punct:]]/, # force 1 punctuation symbol
];

ok String::Tests->pass('Aa0*****', $regexps),
    q| pass |;

ok ! String::Tests->pass('Aa0*****'.chr(0), $regexps),
    q| fail - invalid char |;

ok ! String::Tests->pass('Aa0****', $regexps),
    q| fail - too short |;

ok ! String::Tests->pass('Aa0*****123456789', $regexps),
    q| fail - too long |;

ok ! String::Tests->pass('aa0*****', $regexps),
    q| fail - no upper case |;

ok ! String::Tests->pass('AA0*****', $regexps),
    q| fail - no lower case |;

ok ! String::Tests->pass('Aaa*****', $regexps),
    q| fail - no digit |;

ok ! String::Tests->pass('Aa012345', $regexps),
    q| fail - no punctuation |;


########################################################################
section( 'LIST - CLOSURE TESTS - example simple email validation' );

my $closures = [ # .com .net .org email address?
    sub { shift() =~ /^[A-Z]\w+@(?:[A-Za-z]\w+\.)+(?:com|net|org)\z/i },
    sub { shift() =~ /^foo/ }, # starts with "foo"?
];

ok String::Tests->pass('foo@bar.com', $closures),
    q| pass |;

ok ! String::Tests->pass('foobar.com', $closures),
    q| fail - no @ symbol |;

ok ! String::Tests->pass('foo@info', $closures),
    q| fail - no domain name |;

ok ! String::Tests->pass('foo@bar.info', $closures),
    q| fail - invalid tld |;

ok ! String::Tests->pass('bar@bar.com', $closures),
    q| fail - doesn't start with "foo" |;

########################################################################
section( 'LIST - MIXED REGEXP & CLOSURE TESTS' );

ok String::Tests->pass('foo@Bar0.com', [ @$regexps, @$closures ]),
    q| pass |;

ok ! String::Tests->pass('foo@Bar.com', [ @$regexps, @$closures ]),
    q| fail - failed regexp tests |;

ok ! String::Tests->pass('fooBar0.com', [ @$regexps, @$closures ]),
    q| fail - failed closure tests |;

########################################################################
section( 'SINGLE - REGEXP TEST' );

ok String::Tests->pass('foo', qr/^foo\z/),
    q| pass |;

ok ! String::Tests->pass('bar', qr/^foo\z/),
    q| fail |;

########################################################################
section( 'SINGLE - CLOSURE TEST' );

ok String::Tests->pass('foo', sub { shift() =~ /^foo\z/ } ),
    q| pass |;

ok ! String::Tests->pass('bar', sub { shift() =~ /^foo\z/ } ),
    q| fail |;

########################################################################
section( 'CAPTURE - REGEXP TEST' );
{
    my @blocks_abcd = String::Tests->pass( '10.0.0.1',
        qr/^ (\d{1,3}) \. (\d{1,3}) \. (\d{1,3}) \. (\d{1,3}) \z/x
    );

    is_deeply \@blocks_abcd, [qw( 10 0 0 1 )],
        q| pass - got expected return value |;
}
########################################################################
section( 'CAPTURE - CLOSURE TEST' );
{
    my @blocks_abcd = String::Tests->pass( '10.0.0.1',
        sub { return split( /\./, shift() ) }
    );

    is_deeply \@blocks_abcd, [qw( 10 0 0 1 )],
        q| pass - got expected return value |;
}
########################################################################
section( 'EXCEPTIONS' );

dies_ok { String::Tests->pass(1, {}) }
    q| invalid parameter |;

dies_ok { String::Tests->pass(1, [{}]) }
    q| invalid parameter |;
