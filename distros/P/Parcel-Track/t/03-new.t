#!/usr/bin/perl

# Test the creation of a new Parcel::Track object

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 26;
use Parcel::Track;
use File::Spec::Functions ':ALL';

use Params::Util '_INSTANCE';

sub dies_like {
    my $code = shift;
    my $regexp = _INSTANCE( shift, 'Regexp' )
        or die "Did not provide regexp to dies_like";
    eval { &$code() };
    like( $@, $regexp, $_[0] || "Dies as expected with message like $regexp" );
}

#####################################################################
# Good Creation

# Create a new test tracker
SCOPE: {
    my $tracker1 = Parcel::Track->new( 'Test', '1234-567-890-123' );
    isa_ok( $tracker1, 'Parcel::Track' );

    my $tracker2 = Parcel::Track->new( 'KR::Test', '1234-567-890-123' );
    isa_ok( $tracker2, 'Parcel::Track' );
}

#####################################################################
# Bad Creation

# Parcel::Track provides a fair bit of protection, so that driver authors
# don't have to quite so much.

my $RE_NONAME = qr/Did not provide a Parcel::Track driver name/;
dies_like( sub { Parcel::Track->new },        $RE_NONAME );
dies_like( sub { Parcel::Track->new('') },    $RE_NONAME );
dies_like( sub { Parcel::Track->new(undef) }, $RE_NONAME );
dies_like( sub { Parcel::Track->new( \"" ) }, $RE_NONAME );
dies_like( sub { Parcel::Track->new( [] ) }, $RE_NONAME );
dies_like( sub { Parcel::Track->new( {} ) }, $RE_NONAME );

my $RE_INVALID = qr/Not a valid Parcel::Track driver name/;
dies_like( sub { Parcel::Track->new(' ') },       $RE_INVALID );
dies_like( sub { Parcel::Track->new(' FOO') },    $RE_INVALID );
dies_like( sub { Parcel::Track->new('Foo ') },    $RE_INVALID );
dies_like( sub { Parcel::Track->new(1) },         $RE_INVALID );
dies_like( sub { Parcel::Track->new("Foo'Bar") }, $RE_INVALID );

my $RE_NOID = qr/Did not provide a Parcel::Track tracking number/;
dies_like( sub { Parcel::Track->new('Test') }, $RE_NOID );
dies_like( sub { Parcel::Track->new( 'Test', '' ) },    $RE_NOID );
dies_like( sub { Parcel::Track->new( 'Test', undef ) }, $RE_NOID );
dies_like( sub { Parcel::Track->new( 'Test', \"" ) },   $RE_NOID );
dies_like( sub { Parcel::Track->new( 'Test', [] ) }, $RE_NOID );
dies_like( sub { Parcel::Track->new( 'Test', {} ) }, $RE_NOID );

my $RE_NOEXIST = qr/does not exist, or is not installed/;
dies_like( sub { Parcel::Track->new( "Does::Not::Exist", '1234-567-890-123' ) },
    $RE_NOEXIST );
dies_like( sub { Parcel::Track->new( "FOOOOOOO", '1234-567-890-123' ) },
    $RE_NOEXIST );

SCOPE: {
    local @INC = ( catdir( 't', 'lib' ), @INC );
    dies_like( sub { Parcel::Track->new( 'BAD1', '1234-567-890-123' ) },
        qr/A SPECIFIC ERROR/ );

    dies_like(
        sub { Parcel::Track->new( 'BAD2', '1234-567-890-123' ) },
        qr/does not have Parcel::Track::Role::Base role/
    );
    dies_like( sub { Parcel::Track->new( 'Role::Base', '1234-567-890-123' ) },
        qr/does not have new method/ );

    # Check when the driver dies
    dies_like( sub { Parcel::Track->new( 'BAD3', '1234-567-890-123' ) },
        qr/missing uri, track/ );
    dies_like( sub { Parcel::Track->new( 'BAD4', '1234-567-890-123' ) },
        qr/new dies as expected/ );
}
