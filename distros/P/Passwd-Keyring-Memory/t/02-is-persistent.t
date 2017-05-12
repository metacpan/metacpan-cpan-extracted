#!perl -T

use strict;
use warnings;
use Test::Simple tests => 2;

use Passwd::Keyring::Memory;

my $ring = Passwd::Keyring::Memory->new;

ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Memory',   'new() works' );

ok( $ring->is_persistent eq 0, "is_persistent knows we aren't persistent");

