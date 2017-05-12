#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;
use Test::Exception;

use String::MatchInterpolate;

my $smi = String::MatchInterpolate->new( 'one=${ONE}, two=${TWO}', default_re => qr/\d+/ );

ok( defined $smi, 'defined $smi with default_re' );

is_deeply( scalar $smi->match( "one=123, two=456" ), { ONE => 123, TWO => 456 }, 'matched correct keys' );

is_deeply( scalar $smi->match( "one=abc, two=xyz" ), undef, 'does not match letters' );
