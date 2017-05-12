#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/75-rpc-serialized-server-ucspi.t $
# $LastChangedRevision: 1281 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use Test::More tests => 5;

use_ok('RPC::Serialized::Server::UCSPI');

my $s = RPC::Serialized::Server::UCSPI->new();
isa_ok( $s, 'RPC::Serialized::Server::UCSPI' );
isa_ok( $s, 'RPC::Serialized::Server::STDIO' );
is( $s->ifh->fileno, fileno(STDIN) );
is( $s->ofh->fileno, fileno(STDOUT) );
