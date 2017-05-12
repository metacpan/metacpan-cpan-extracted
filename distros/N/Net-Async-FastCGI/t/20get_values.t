#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use Test::More tests => 3;
use Test::HexString;

use IO::Async::Loop;
use IO::Async::Test;

use Net::Async::FastCGI;

use TestFCGI;

my ( $S, $selfaddr ) = make_server_sock;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $fcgi = Net::Async::FastCGI->new(
   handle => $S,
   on_request => sub {}, # ignore, we're not really going to start any
);

$loop->add( $fcgi );

my $C = connect_client_sock( $selfaddr );

$C->syswrite(
   # FCGI_GET_VALUES
   fcgi_trans( 
      type => 9,
      id   => 0,
      data => "\x0f\0FCGI_MPXS_CONNS"
   )
);

my $expect;

$expect =
   # FCGI_GET_VALUES_RESULT
   fcgi_trans(
      type => 10,
      id   => 0,
      data => "\x0f\1FCGI_MPXS_CONNS1"
   );

my $buffer;

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI end request record for FCGI_MPXS_CONNS' );

$C->syswrite(
   # FCGI_GET_VALUES
   fcgi_trans( 
      type => 9,
      id   => 0,
      data => "\x0e\0FCGI_MAX_CONNS"
   )
);

$expect =
   # FCGI_GET_VALUES_RESULT
   fcgi_trans(
      type => 10,
      id   => 0,
      data => "\x0e\4FCGI_MAX_CONNS1024"
   );

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI end request record for FCGI_MAX_CONNS' );

$C->syswrite(
   # FCGI_GET_VALUES
   fcgi_trans( 
      type => 9,
      id   => 0,
      data => "\x0d\0FCGI_MAX_REQS"
   )
);

$expect =
   # FCGI_GET_VALUES_RESULT
   fcgi_trans(
      type => 10,
      id   => 0,
      data => "\x0d\4FCGI_MAX_REQS1024"
   );

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI end request record for FCGI_MAX_REQS' );
