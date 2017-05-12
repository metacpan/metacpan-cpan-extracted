#$Id$
use Test::More;
use Test::Exception;
use Module::Build;
use lib '../lib';
use REST::Neo4p;
use strict;
use warnings;
no warnings qw(once);
#$SIG{__DIE__} = sub { if (ref $_[0]) { $_[0]->rethrow } else { print $_[0] }};

my $a;
lives_ok { $a = REST::Neo4p::Agent->new() } "can make a default Agent";
isa_ok $a, "REST::Neo4p::Agent::LWP::UserAgent";
done_testing;
