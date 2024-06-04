#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Tags::HTML;
use Plack::Runner;
use Tags::HTML::Message::Board;
use Tags::Output::Indent;
use Test::Shared::Fixture::Data::Message::Board::Example;

my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'no_simple' => ['textarea'],
        'preserved' => ['style', 'textarea'],
        'xml' => 1,
);
my $message_board = Tags::HTML::Message::Board->new(
        'css' => $css,
        'tags' => $tags,
);
my $board = Test::Shared::Fixture::Data::Message::Board::Example->new;
$message_board->process_css;
my $app = Plack::App::Tags::HTML->new(
        'component' => 'Tags::HTML::Container',
        'data' => [sub {
                my $self = shift;
                $message_board->process_css;
                $message_board->init($board);
                $message_board->process;
                return;
        }],
        'css' => $css,
        'tags' => $tags,
)->to_app;
Plack::Runner->new->run($app);

# Output screenshot is in images/ directory.