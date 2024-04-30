#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Tags::HTML;
use Plack::Runner;
use Tags::HTML::Login::Request;
use Tags::Output::Indent;
use Unicode::UTF8 qw(decode_utf8);

my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
        'preserved' => ['style'],
);
my $login_request = Tags::HTML::Login::Request->new(
        'css' => $css,
        'tags' => $tags,
);
$login_request->process_css;
my $app = Plack::App::Tags::HTML->new(
        'component' => 'Tags::HTML::Container',
        'data' => [sub {
                my $self = shift;
                $login_request->process;
                $login_request->process_css;
                return;
        }],
        'css' => $css,
        'tags' => $tags,
        'title' => 'Login and password',
)->to_app;
Plack::Runner->new->run($app);

# Output screenshot is in images/ directory.