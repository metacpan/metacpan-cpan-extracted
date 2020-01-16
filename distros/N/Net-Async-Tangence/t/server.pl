#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
   use File::Basename qw( dirname );
   # this script lives in SRCDIR/t/server.pl
   # chdir to SRCDIR
   chdir dirname( dirname( $0 ) );
}
use blib;

use IO::Async::Loop;

use Tangence::Registry;

use Net::Async::Tangence::Server;

use lib ".";
use t::TestObj;

my $loop = IO::Async::Loop->new();

my $registry = Tangence::Registry->new(
   tanfile => "t/TestObj.tan",
);
my $obj = $registry->construct(
   "t::TestObj",
   scalar   => 123,
   s_scalar => 456,
);
my $server = Net::Async::Tangence::Server->new(
   registry => $registry,
);
$loop->add( $server );

$server->accept_stdio
   ->configure( on_closed => sub { $loop->stop } );
$loop->run;
