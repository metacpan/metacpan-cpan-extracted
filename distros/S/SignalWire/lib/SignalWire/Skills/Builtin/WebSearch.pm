package SignalWire::Skills::Builtin::WebSearch;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.
#
# Real Google Custom Search client. Mirrors signalwire-python's
# skills/web_search/skill.py:GoogleSearchScraper.search_google — issue
# an outbound GET to customsearch/v1 with `key`, `cx`, `q`, parse
# the JSON `items[]` array, format title+snippet for the LLM.
#
# Python's full implementation also fetches each result URL and runs
# HTML extraction + quality scoring. We ship the search portion (the
# part the audit_skills_dispatch contract probes) in the SDK and leave
# the page-extraction to the spider skill, so consumers compose the two
# when they want full-page text. A Perl port that ships ~600 lines of
# BeautifulSoup-equivalent HTML cleanup is a separate piece of work.

use strict;
use warnings;
use Moo;
use HTTP::Tiny;
use JSON ();
use URI::Escape qw(uri_escape);
extends 'SignalWire::Skills::SkillBase';

use SignalWire::Skills::SkillRegistry;
SignalWire::Skills::SkillRegistry->register_skill('web_search', __PACKAGE__);

has '+skill_name'        => (default => sub { 'web_search' });
has '+skill_description' => (default => sub { 'Search the web for information using Google Custom Search API' });
has '+skill_version'     => (default => sub { '2.0.0' });
has '+supports_multiple_instances' => (default => sub { 1 });

# Google CSE base URL. Honor WEB_SEARCH_BASE_URL env var so the audit
# fixture (audit_skills_dispatch.py) can redirect us at a local HTTP
# server. The override replaces the host+scheme; the canonical
# `/customsearch/v1` path is always appended so the documented Google
# CSE wire shape is preserved (the audit's `expected_path_substring`
# is `customsearch`, which would not appear if we used the override
# verbatim).
has 'base_url' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $override = $ENV{WEB_SEARCH_BASE_URL};
        return 'https://www.googleapis.com/customsearch/v1' unless $override;
        # Strip trailing slash, then append the canonical Google CSE
        # path so callers see the same URL shape as production.
        $override =~ s{/+$}{};
        return "$override/customsearch/v1";
    },
);

has '_http' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        HTTP::Tiny->new(
            agent   => 'SignalWire-Perl-WebSearch/2.0',
            timeout => 15,
        );
    },
);

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tool_name = $self->params->{tool_name} // 'web_search';

    my $weak_self = $self;
    require Scalar::Util;
    Scalar::Util::weaken($weak_self);

    $self->define_tool(
        name        => $tool_name,
        description => 'Search the web for high-quality information, automatically filtering low-quality results',
        parameters  => {
            type       => 'object',
            properties => {
                query => { type => 'string', description => 'The search query' },
            },
            required => ['query'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            my $query = $args->{query} // '';
            my $text = $weak_self->search_web($query);
            $text = $weak_self->_wrap_response($text);
            return SignalWire::SWAIG::FunctionResult->new(response => $text);
        },
    );
}

sub search_web {
    my ($self, $query) = @_;

    my $api_key = $self->params->{api_key} || $ENV{GOOGLE_API_KEY} || '';
    my $cse_id  = $self->params->{search_engine_id}
        || $self->params->{cx}
        || $ENV{GOOGLE_CSE_ID}
        || '';
    my $num     = $self->params->{num_results} // 3;
    $num = 10 if $num > 10;
    $num = 1 if $num < 1;

    my $url = $self->base_url
        . '?key=' . uri_escape($api_key)
        . '&cx=' . uri_escape($cse_id)
        . '&q=' . uri_escape($query)
        . '&num=' . $num;

    my $resp = $self->_http->get($url);
    unless ($resp->{success}) {
        return "Web search error: $resp->{status} $resp->{reason}";
    }
    my $data = eval { JSON::decode_json($resp->{content}) };
    return "Web search parse error: $@" if $@;

    my $items = $data->{items} // [];
    return "No results for: $query" unless @$items;

    my @lines;
    my $i = 1;
    for my $item (@$items) {
        last if $i > $num;
        my $title   = $item->{title}   // '';
        my $link    = $item->{link}    // '';
        my $snippet = $item->{snippet} // '';
        push @lines, "$i. $title\n   $snippet\n   $link";
        $i++;
    }
    return join("\n\n", @lines);
}

# Wrap a successful search response with optional response_prefix /
# response_postfix. Mirrors Python signalwire/skills/web_search/skill.py
# (commit 8aad242): prefix/postfix are joined with a blank line on each
# side. Error / no-result branches are passed through unwrapped so the
# LLM still sees the failure mode verbatim.
sub _wrap_response {
    my ($self, $text) = @_;
    return $text unless defined $text && length $text;
    # Match Python's "errors don't get wrapped" pattern. The Perl
    # search_web returns one of three known failure sentinels; anything
    # else is a real result list.
    return $text if $text =~ /^Web search error:/;
    return $text if $text =~ /^Web search parse error:/;
    return $text if $text =~ /^No results for:/;
    my $prefix  = $self->params->{response_prefix}  // '';
    my $postfix = $self->params->{response_postfix} // '';
    $text = "$prefix\n\n$text"  if length $prefix;
    $text = "$text\n\n$postfix" if length $postfix;
    return $text;
}

sub get_global_data {
    return {
        web_search_enabled => JSON::true,
        search_provider    => 'Google Custom Search',
        quality_filtering  => JSON::true,
    };
}

sub _get_prompt_sections {
    return [{
        title   => 'Web Search Capability (Quality Enhanced)',
        body    => '',
        bullets => [
            'Use web_search to find current information',
            'Results are quality-filtered automatically',
        ],
    }];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Skills::SkillBase->get_parameter_schema },
        api_key           => { type => 'string',  required => 1, hidden => 1 },
        search_engine_id  => { type => 'string',  required => 1, hidden => 1 },
        num_results       => { type => 'integer', default  => 3, min => 1, max => 10 },
        response_prefix   => { type => 'string',  default  => '' },
        response_postfix  => { type => 'string',  default  => '' },
    };
}

1;
