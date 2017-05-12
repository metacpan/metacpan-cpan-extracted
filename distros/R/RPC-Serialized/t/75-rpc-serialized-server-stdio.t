#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/75-rpc-serialized-server-stdio.t $
# $LastChangedRevision: 1281 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use Test::More tests => 6;

use_ok('RPC::Serialized::Server::STDIO');

my $s = RPC::Serialized::Server::STDIO->new();
isa_ok( $s, 'RPC::Serialized::Server::STDIO' );
isa_ok( $s, 'RPC::Serialized::Server' );
isa_ok( $s, 'RPC::Serialized' );
is( $s->ifh->fileno, fileno(STDIN) );
is( $s->ofh->fileno, fileno(STDOUT) );
