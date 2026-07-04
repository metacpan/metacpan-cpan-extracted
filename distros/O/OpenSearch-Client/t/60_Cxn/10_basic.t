# OpenSearch::Client is an unofficial client for OpenSearch. 
# It is derived from Search::Elasticsearch version 7.714
# License details from the original work are contained in the
# NOTICE file distributed with this work.
#
#-----------------------------------------------------------------------
# OpenSearch::Client
#-----------------------------------------------------------------------
# Copyright 2026 Mark Dootson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use Test::More;
use OpenSearch::Client;

my $c = OpenSearch::Client->new->transport->cxn_pool->cxns->[0];
ok $c->does('OpenSearch::Client::Role::Cxn'),
    'Does OpenSearch::Client::Role::Cxn';

# MARK LIVE

$c->mark_live;

ok $c->is_live,       "Cxn is live";
is $c->ping_failures, 0, "No ping failures";
is $c->next_ping,     0, "No ping scheduled";

# MARK DEAD

$c->mark_dead;

ok $c->is_dead, "Cxn is dead";
is $c->ping_failures, 1, "Has ping failure";
ok $c->next_ping > time(), "Ping scheduled";
ok $c->next_ping <= time() + $c->dead_timeout, "Dead timeout x 1";

$c->mark_dead;
ok $c->is_dead, "Cxn still dead";
is $c->ping_failures, 2, "Has 2 ping failures";
ok $c->next_ping > time(), "Ping scheduled";
ok $c->next_ping <= time() + 2 * $c->dead_timeout, "Dead timeout x 2";

$c->mark_dead for 1 .. 100;
ok $c->is_dead, "Cxn still dead";
is $c->ping_failures, 102, "Has 102 ping failures";
ok $c->next_ping > time(), "Ping scheduled";
ok $c->next_ping <= time() + $c->max_dead_timeout, "Max dead timeout";

# FORCE PING

$c->force_ping;
ok $c->is_dead,       "Cxn is dead after force ping";
is $c->ping_failures, 0, "Force ping has no ping failures";
is $c->next_ping,     -1, "Next ping scheduled for now";

done_testing;
