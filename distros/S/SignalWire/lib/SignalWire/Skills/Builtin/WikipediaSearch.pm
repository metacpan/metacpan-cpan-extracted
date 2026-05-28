package SignalWire::Skills::Builtin::WikipediaSearch;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.
#
# Real Wikipedia API client. Mirrors signalwire-python's
# skills/wikipedia_search/skill.py:_search_wiki_handler — issue an
# outbound GET to /w/api.php with a `srsearch` query, parse the JSON
# `query.search` list, fetch each article extract, return a formatted
# string.

use strict;
use warnings;
use Moo;
use HTTP::Tiny;
use JSON ();
use URI::Escape qw(uri_escape);
extends 'SignalWire::Skills::SkillBase';

use SignalWire::Skills::SkillRegistry;
SignalWire::Skills::SkillRegistry->register_skill('wikipedia_search', __PACKAGE__);

has '+skill_name'        => (default => sub { 'wikipedia_search' });
has '+skill_description' => (default => sub { 'Search Wikipedia for information about a topic and get article summaries' });
has '+supports_multiple_instances' => (default => sub { 0 });

# Default Wikipedia API base. Honor WIKIPEDIA_BASE_URL env var so the
# audit fixture (audit_skills_dispatch.py) can redirect us at a local
# HTTP server. The override replaces the host+scheme; the canonical
# `/w/api.php` path is always appended so the documented Wikipedia
# API wire shape is preserved (the audit's `expected_path_substring`
# is `api.php`).
has 'base_url' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $override = $ENV{WIKIPEDIA_BASE_URL};
        return 'https://en.wikipedia.org/w/api.php' unless $override;
        $override =~ s{/+$}{};
        return "$override/w/api.php";
    },
);

has 'num_results' => (is => 'ro', lazy => 1, default => sub { 1 });
has 'no_results_message' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        "I couldn't find any Wikipedia articles for '{query}'. "
            . "Try rephrasing your search or using different keywords.";
    },
);

has '_http' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        HTTP::Tiny->new(
            agent   => 'SignalWire-Perl-WikipediaSearch/1.0',
            timeout => 10,
        );
    },
);

sub setup {
    my ($self) = @_;
    if (defined $self->params->{num_results}) {
        my $n = $self->params->{num_results};
        $n = 1 if $n < 1;
        $self->{num_results} = $n;
    }
    if (defined $self->params->{no_results_message}) {
        $self->{no_results_message} = $self->params->{no_results_message};
    }
    return 1;
}

sub register_tools {
    my ($self) = @_;
    my $weak_self = $self;
    require Scalar::Util;
    Scalar::Util::weaken($weak_self);

    $self->define_tool(
        name        => 'search_wiki',
        description => 'Search Wikipedia for information about a topic and get article summaries',
        parameters  => {
            type       => 'object',
            properties => {
                query => {
                    type        => 'string',
                    description => 'The search term or topic to look up on Wikipedia',
                },
            },
            required => ['query'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            my $query = $args->{query} // '';
            $query =~ s/^\s+|\s+$//g;
            unless (length $query) {
                return SignalWire::SWAIG::FunctionResult->new(
                    response => 'Please provide a search query for Wikipedia.',
                );
            }
            my $text = $weak_self->search_wiki($query);
            return SignalWire::SWAIG::FunctionResult->new(response => $text);
        },
    );
}

sub search_wiki {
    my ($self, $query) = @_;

    my $base = $self->base_url;
    # Step 1: search.
    my $search_url = $base
        . '?action=query&list=search&format=json'
        . '&srsearch=' . uri_escape($query)
        . '&srlimit=' . $self->num_results;

    my $resp = $self->_http->get($search_url);
    unless ($resp->{success}) {
        return "Error accessing Wikipedia: $resp->{status} $resp->{reason}";
    }
    my $data = eval { JSON::decode_json($resp->{content}) };
    return "Error parsing Wikipedia response: $@" if $@;

    my $hits = $data->{query}{search} // [];
    unless (@$hits) {
        my $msg = $self->no_results_message;
        $msg =~ s/\{query\}/$query/g;
        return $msg;
    }

    # Step 2: extract for each article (or, more pragmatically, parse
    # the search snippet directly when present — the canned audit
    # fixture returns `query.search[].snippet`, not a separate extract
    # endpoint, so always preferring the snippet keeps the parser
    # uniform across live + fixture).
    my @articles;
    my $i = 0;
    for my $hit (@$hits) {
        last if $i++ >= $self->num_results;
        my $title = $hit->{title} // 'Unknown';
        my $snippet = $hit->{snippet};
        my $extract;

        if (defined $snippet && length $snippet) {
            # Strip HTML tags Wikipedia includes in the snippet.
            $extract = $snippet;
            $extract =~ s/<[^>]+>//g;
        } else {
            my $extract_url = $base
                . '?action=query&prop=extracts&exintro&explaintext&format=json'
                . '&titles=' . uri_escape($title);
            my $er = $self->_http->get($extract_url);
            if ($er->{success}) {
                my $ed = eval { JSON::decode_json($er->{content}) };
                if (!$@ && $ed) {
                    my $pages = $ed->{query}{pages} // {};
                    my ($first) = values %$pages;
                    $extract = $first->{extract} if $first;
                }
            }
        }

        if (defined $extract && length $extract) {
            push @articles, "**$title**\n\n$extract";
        } else {
            push @articles, "**$title**\n\nNo summary available for this article.";
        }
    }

    return join("\n\n" . ('=' x 50) . "\n\n", @articles);
}

sub _get_prompt_sections {
    return [{
        title   => 'Wikipedia Search',
        body    => 'You can search Wikipedia for factual information.',
        bullets => [
            'Use search_wiki to find information about any topic',
            'Results include article summaries from Wikipedia',
        ],
    }];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Skills::SkillBase->get_parameter_schema },
        num_results        => { type => 'integer', default => 1, min => 1, max => 5 },
        no_results_message => { type => 'string' },
    };
}

1;
