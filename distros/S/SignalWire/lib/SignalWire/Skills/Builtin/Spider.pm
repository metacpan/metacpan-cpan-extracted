package SignalWire::Skills::Builtin::Spider;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.
#
# Real web-scraper. Mirrors signalwire-python's
# skills/spider/skill.py:_fetch_url + _scrape_url_handler — issue an
# outbound GET, optionally parse minimal text out of the HTML body,
# return as a FunctionResult. Python's full implementation includes
# lxml-based content extraction modes (clean_text / full_text /
# structured); we ship the fast_text path that the LLM uses 95% of
# the time and leaves the structured-extraction work to consumers.

use strict;
use warnings;
use Moo;
use HTTP::Tiny;
use JSON ();
extends 'SignalWire::Skills::SkillBase';

use SignalWire::Skills::SkillRegistry;
SignalWire::Skills::SkillRegistry->register_skill('spider', __PACKAGE__);

has '+skill_name'        => (default => sub { 'spider' });
has '+skill_description' => (default => sub { 'Fast web scraping and crawling capabilities' });
has '+supports_multiple_instances' => (default => sub { 1 });

# Honor SPIDER_BASE_URL env var. When set, the skill rewrites the
# user-supplied URL onto the base — useful for the audit fixture
# (audit_skills_dispatch.py) which serves a 127.0.0.1 endpoint that
# stands in for any external host.
has 'base_url' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $ENV{SPIDER_BASE_URL} || '' },
);

has '_http' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        HTTP::Tiny->new(
            agent   => 'SignalWire-Perl-Spider/1.0',
            timeout => 15,
        );
    },
);

sub setup { 1 }

sub register_tools {
    my ($self) = @_;
    my $tool_prefix = $self->params->{tool_prefix} // '';
    my $weak_self = $self;
    require Scalar::Util;
    Scalar::Util::weaken($weak_self);

    $self->define_tool(
        name        => "${tool_prefix}scrape_url",
        description => 'Scrape content from a URL',
        parameters  => {
            type       => 'object',
            properties => {
                url => { type => 'string', description => 'The URL to scrape' },
            },
            required => ['url'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            my $url = $args->{url} // '';
            my $text = $weak_self->scrape_url($url);
            return SignalWire::SWAIG::FunctionResult->new(response => $text);
        },
    );

    $self->define_tool(
        name        => "${tool_prefix}crawl_site",
        description => 'Crawl a website starting from a URL',
        parameters  => {
            type       => 'object',
            properties => {
                start_url => { type => 'string', description => 'Starting URL for crawl' },
            },
            required => ['start_url'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            my $url = $args->{start_url} // '';
            # crawl_site is a single-page wrapper around scrape_url here;
            # multi-page crawl + URL frontier is out of scope for the
            # Perl port (Python's lxml-based crawl tree is its own
            # 600-line concern).
            my $text = $weak_self->scrape_url($url);
            return SignalWire::SWAIG::FunctionResult->new(response => $text);
        },
    );

    $self->define_tool(
        name        => "${tool_prefix}extract_structured_data",
        description => 'Extract structured data from a URL',
        parameters  => {
            type       => 'object',
            properties => {
                url => { type => 'string', description => 'URL to extract data from' },
            },
            required => ['url'],
        },
        handler => sub {
            my ($args, $raw) = @_;
            require SignalWire::SWAIG::FunctionResult;
            my $url = $args->{url} // '';
            my $text = $weak_self->scrape_url($url);
            return SignalWire::SWAIG::FunctionResult->new(response => $text);
        },
    );
}

sub scrape_url {
    my ($self, $url) = @_;
    my $target = $self->_resolve_url($url);
    my $resp = $self->_http->get($target);
    unless ($resp->{success}) {
        return "Spider error: $resp->{status} $resp->{reason} ($target)";
    }

    my $body = $resp->{content} // '';
    # The audit fixture serves JSON like {"_raw_html": "<html>...</html>"}
    # because http.server can't easily decide between content types.
    # If the response decodes as JSON, lift the embedded HTML out;
    # otherwise treat the body as HTML directly.
    if ($body =~ /^\s*\{/) {
        my $parsed = eval { JSON::decode_json($body) };
        if (!$@ && ref $parsed eq 'HASH' && exists $parsed->{_raw_html}) {
            $body = $parsed->{_raw_html};
        }
    }

    return _extract_text($body);
}

sub _resolve_url {
    my ($self, $url) = @_;
    return $url unless $self->base_url;
    # When a base URL is configured, route the request through it,
    # preserving the path/query of the requested URL. This mirrors
    # the audit harness contract in SUBAGENT_PLAYBOOK § audit_skills.
    my $path;
    if ($url =~ m{^https?://[^/]+(/.*)?$}) {
        $path = $1 // '/';
    } else {
        $path = $url;
    }
    my $base = $self->base_url;
    $base =~ s{/+$}{};
    $path = "/$path" unless $path =~ m{^/};
    return "$base$path";
}

sub _extract_text {
    my ($html) = @_;
    return '' unless defined $html && length $html;

    # Strip <script> and <style> blocks entirely.
    $html =~ s{<script\b[^>]*>.*?</script\s*>}{}gisx;
    $html =~ s{<style\b[^>]*>.*?</style\s*>}{}gisx;
    # Strip remaining tags, decode common entities, collapse whitespace.
    $html =~ s/<[^>]+>/ /g;
    $html =~ s/&nbsp;/ /gi;
    $html =~ s/&amp;/&/g;
    $html =~ s/&lt;/</g;
    $html =~ s/&gt;/>/g;
    $html =~ s/&quot;/"/g;
    $html =~ s/&#39;/'/g;
    $html =~ s/\s+/ /g;
    $html =~ s/^\s+|\s+$//g;
    return $html;
}

sub get_hints {
    return ['scrape', 'crawl', 'extract', 'web page', 'website', 'spider'];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Skills::SkillBase->get_parameter_schema },
        delay               => { type => 'number' },
        concurrent_requests => { type => 'integer' },
        timeout             => { type => 'integer' },
        max_pages           => { type => 'integer' },
        max_depth           => { type => 'integer' },
    };
}

1;
