use Test::More;
use lib '../../lib'; # testing
use v5.10;
use REST::Neo4p::Agent;
use strict;
use warnings;


ok my $agent = REST::Neo4p::Agent->new(agent_module => 'Neo4j::Driver');
done_testing;
