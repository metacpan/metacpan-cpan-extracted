#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;

use IO::Async::Loop 0.48;
use IO::Async::OS;

use Term::TermKey::Async;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $rd, $wr ) = IO::Async::OS->pipepair or die "Cannot pipe() - $!";

# Sanitise this just in case
$ENV{TERM} = "vt100";

my $key;

my $tka = Term::TermKey::Async->new(
   term => $rd,
   on_key => sub { ( undef, $key ) = @_; },
);

$loop->add( $tka );

ok( !defined $key, '$key is not yet defined' );

$wr->syswrite( "\e" );

my $wait = 0;
$loop->watch_time(
   after => $tka->get_waittime / 2000,
   code => sub { $wait++ },
);

wait_for { $wait };

ok( !defined $key, '$key still not defined after 1/2 waittime' );

wait_for { defined $key };

ok( $key->type_is_keysym,                   '$key->type_is_keysym after Escape timeout' );
is( $key->sym, $tka->keyname2sym("Escape"), '$key->keysym after Escape timeout' );
is( $key->modifiers, 0,                     '$key->modifiers after Escape timeout' );

done_testing;
