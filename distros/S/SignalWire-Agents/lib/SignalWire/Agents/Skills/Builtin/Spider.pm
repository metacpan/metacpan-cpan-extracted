package SignalWire::Agents::Skills::Builtin::Spider;
use strict;
use warnings;
use Moo;
extends 'SignalWire::Agents::Skills::SkillBase';

use SignalWire::Agents::Skills::SkillRegistry;
SignalWire::Agents::Skills::SkillRegistry->register_skill('spider', __PACKAGE__);

has '+skill_name'        => (default => sub { 'spider' });
has '+skill_description' => (default => sub { 'Fast web scraping and crawling capabilities' });
has '+supports_multiple_instances' => (default => sub { 1 });

sub setup { 1 }

sub register_tools {
    my ($self) = @_;

    $self->define_tool(
        name        => 'scrape_url',
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
            require SignalWire::Agents::SWAIG::FunctionResult;
            return SignalWire::Agents::SWAIG::FunctionResult->new(
                response => "Scraped content from: $args->{url}"
            );
        },
    );

    $self->define_tool(
        name        => 'crawl_site',
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
            require SignalWire::Agents::SWAIG::FunctionResult;
            return SignalWire::Agents::SWAIG::FunctionResult->new(
                response => "Crawling site from: $args->{start_url}"
            );
        },
    );

    $self->define_tool(
        name        => 'extract_structured_data',
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
            require SignalWire::Agents::SWAIG::FunctionResult;
            return SignalWire::Agents::SWAIG::FunctionResult->new(
                response => "Extracted structured data from: $args->{url}"
            );
        },
    );
}

sub get_hints {
    return ['scrape', 'crawl', 'extract', 'web page', 'website', 'spider'];
}

sub get_parameter_schema {
    return {
        %{ SignalWire::Agents::Skills::SkillBase->get_parameter_schema },
        delay               => { type => 'number' },
        concurrent_requests => { type => 'integer' },
        timeout             => { type => 'integer' },
        max_pages           => { type => 'integer' },
        max_depth           => { type => 'integer' },
    };
}

1;
