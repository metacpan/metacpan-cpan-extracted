#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Tags::HTML;
use Plack::Runner;
use Tags::HTML::Message::Board::Blank;
use Tags::Output::Indent;

my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'no_simple' => ['textarea'],
        'preserved' => ['style', 'textarea'],
        'xml' => 1,
);
my $message_board_blank = Tags::HTML::Message::Board::Blank->new(
        'css' => $css,
        'tags' => $tags,
);
$message_board_blank->process_css;
my $app = Plack::App::Tags::HTML->new(
        'component' => 'Tags::HTML::Container',
        'data' => [sub {
                my $self = shift;
                $message_board_blank->process_css;
                $message_board_blank->process;
                return;
        }],
        'css' => $css,
        'tags' => $tags,
)->to_app;
Plack::Runner->new->run($app);

# Output screenshot is in images/ directory.