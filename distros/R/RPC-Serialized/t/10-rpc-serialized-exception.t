#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/10-rpc-serialized-exception.t $
# $LastChangedRevision: 1323 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use strict;
use warnings;

use Test::More tests => 30;

use_ok('RPC::Serialized::Exceptions');

my @classes = qw(RPC::Serialized::X
    RPC::Serialized::X::Protocol
    RPC::Serialized::X::Parse
    RPC::Serialized::X::System
    RPC::Serialized::X::Application
    RPC::Serialized::X::Authorization
    RPC::Serialized::X::Validation);

ok( eq_set( [ RPC::Serialized::X->Classes ], \@classes ) );

foreach (@classes) {
    my $e = $_->new("some text");
    isa_ok( $e, $_ );
    isa_ok( $e, 'RPC::Serialized::X' );
    can_ok( $e, 'throw' );
    is( $e->message, "some text" );
}
