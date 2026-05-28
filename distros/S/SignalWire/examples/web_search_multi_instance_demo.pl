#!/usr/bin/env perl
# Web Search Multiple Instance Demo
#
# Loads the web search skill multiple times with different tool names
# (general, news, quick). Also includes Wikipedia search.
#
# Required: GOOGLE_SEARCH_API_KEY, GOOGLE_SEARCH_ENGINE_ID

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;

my $api_key   = $ENV{GOOGLE_SEARCH_API_KEY};
my $engine_id = $ENV{GOOGLE_SEARCH_ENGINE_ID};

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'Multi-Search Assistant',
    route => '/multi-search',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

$agent->prompt_add_section('Role',
    'You are a research assistant with access to multiple search tools. '
    . 'Use the most appropriate tool for each query.');

eval { $agent->add_skill('datetime') };
eval { $agent->add_skill('math') };

# Wikipedia search
eval {
    $agent->add_skill('wikipedia_search', { num_results => 2 });
    print "Added Wikipedia search (tool: search_wiki)\n";
};
print "Wikipedia: $@\n" if $@;

unless ($api_key && $engine_id) {
    print "Warning: Missing GOOGLE_SEARCH_API_KEY or GOOGLE_SEARCH_ENGINE_ID.\n";
    print "Web search instances will not be available.\n";
} else {
    # Instance 1: General web search (default tool name)
    eval {
        $agent->add_skill('web_search', {
            api_key          => $api_key,
            search_engine_id => $engine_id,
            num_results      => 3,
        });
        print "Added general web search (tool: web_search)\n";
    };
    print "General search: $@\n" if $@;

    # Instance 2: News search
    eval {
        $agent->add_skill('web_search', {
            api_key          => $api_key,
            search_engine_id => $engine_id,
            tool_name        => 'search_news',
            num_results      => 5,
            delay            => 0.5,
        });
        print "Added news search (tool: search_news)\n";
    };
    print "News search: $@\n" if $@;

    # Instance 3: Quick single-result search
    eval {
        $agent->add_skill('web_search', {
            api_key          => $api_key,
            search_engine_id => $engine_id,
            tool_name        => 'quick_search',
            num_results      => 1,
            delay            => 0,
        });
        print "Added quick search (tool: quick_search)\n";
    };
    print "Quick search: $@\n" if $@;
}

print "\nTools: web_search, search_news, quick_search, search_wiki\n";
print "Starting Multi-Search agent...\n\n";

$agent->run;
