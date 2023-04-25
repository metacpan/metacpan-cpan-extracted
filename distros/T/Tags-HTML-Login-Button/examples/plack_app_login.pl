#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Tags::HTML;
use Plack::Runner;
use Tags::Output::Indent;
use Unicode::UTF8 qw(decode_utf8);

my $app = Plack::App::Tags::HTML->new(
        'component' => 'Tags::HTML::Login::Button',
        'constructor_args' => {
                'title' => decode_utf8('Přihlašovací tlačítko'),
        },
        'css' => CSS::Struct::Output::Indent->new,
        'tags' => Tags::Output::Indent->new(
                'xml' => 1,
                'preserved' => ['style'],
        ),
        'title' => decode_utf8('Přihlašovací tlačítko'),
)->to_app;
Plack::Runner->new->run($app);