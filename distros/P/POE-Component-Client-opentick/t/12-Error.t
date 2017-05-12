#!/usr/bin/perl
#
#   Unit tests for ::Error.pm
#
#   infi/2008
#

use strict;
use warnings;

use Test::More tests => 13;
use Data::Dumper;

BEGIN {
    # Test #1
    use_ok( 'POE::Component::Client::opentick::Util' );
    # Test #2
    use_ok( 'POE::Component::Client::opentick::Constants' );
    # Test #3
    use_ok( 'POE::Component::Client::opentick::Error' );
}

# Some of these functions were tested previously.
my $err_num = OTConstant( 'OT_ERR_BAD_LOGIN' );
my $err_msg = 'Something kasplodinated!';
my $err_len = length( $err_msg );
my $err_bin =
        pack_binary( OTTemplate( 'ERROR' ), $err_num, $err_len, $err_msg );
my ($obj, $another_obj);

# Test: Object creation with static message
isa_ok(
    $obj = POE::Component::Client::opentick::Error->new(
                        Message     => $err_msg,
    ),
    'POE::Component::Client::opentick::Error'
);

# Test: Make sure simple stringification overloading "worked"
is( "$obj", $err_msg, 'simple Error object stringification' );

# Test: Complex object creation with binary OT error data
isa_ok(
    $obj = POE::Component::Client::opentick::Error->new(
                        Data        => $err_bin,
                        CommandID   => OTConstant( 'OT_LOGIN' ),
                        RequestID   => 42,
    ),
    'POE::Component::Client::opentick::Error'
);

# Test: Complex object stringification
ok(
    "$obj" eq "Protocol error 1001: Something kasplodinated!\n" .
              "OTCommand: 1 (OT_LOGIN)\n" .
              "Request ID: 42",
    'complex Error object stringification',
);

# Test: throw()
ok(
    do { eval { throw( 'Grandma says knock you out' ) }; $@ }
        =~ m#^Grandma says knock you out at .*/12-Error\.t line .*#,
    'throw() correctness',
);

# Test #8: Util.pm's exported is_error works on Error object
is( is_error( $obj ),             1, 'is_error( Error object )' );
is( is_error( qw/FROO/ ),         0, 'is_error( string )' );
is( is_error( 142983 ),           0, 'is_error( number )' );
is( is_error( [ qw/hi mom/ ] ),   0, 'is_error( list )' );
is( is_error( Data::Dumper->new( [qw/meow/] ) ), 0,
            'is_error( random object )' );

__END__
