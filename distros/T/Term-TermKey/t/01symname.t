#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Term::TermKey;

my $tk = Term::TermKey->new_abstract( "vt100", 0 );

defined $tk or die "Cannot create termkey instance";

# We know 'Space' ought to exist
my $sym = $tk->keyname2sym( 'Space' );

ok( defined $sym, "defined keyname2sym('Space')" );

is( $tk->get_keyname( $sym ), 'Space', "get_keyname eq Space" );

done_testing;
