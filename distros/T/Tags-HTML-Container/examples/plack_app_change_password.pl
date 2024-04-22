#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Tags::HTML;
use Plack::Runner;
use Tags::HTML::ChangePassword;
use Tags::Output::Indent;

my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
        'preserved' => ['style'],
);
my $change_password = Tags::HTML::ChangePassword->new(
        'css' => $css,
        'tags' => $tags,
);
$change_password->process_css;
my $app = Plack::App::Tags::HTML->new(
        'component' => 'Tags::HTML::Container',
        'data' => [sub {
                my $self = shift;
                $change_password->process;
                return;
        }],
        'css' => $css,
        'tags' => $tags,
)->to_app;
Plack::Runner->new->run($app);

# Output screenshot is in images/ directory.