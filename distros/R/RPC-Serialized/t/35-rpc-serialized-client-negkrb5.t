#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/35-rpc-serialized-client-negkrb5.t $
# $LastChangedRevision: 1281 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use strict;
use warnings;

use Test::More tests => 1;

SKIP: {
    skip( "Cannot load IO::Socket::NegKrb5", 1 )
        unless eval { require IO::Socket::NegKrb5 };
    use_ok('RPC::Serialized::Client::NegKrb5');
}
