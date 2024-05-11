#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::Navigation::Item;
use Plack::App::Tags::HTML;
use Plack::Builder;
use Plack::Runner;
use Tags::Output::Indent;

# Plack application with foo SVG file.
my $svg_foo = <<'END';
<?xml version="1.0" ?>
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="-1 -1 2 2">
  <polygon points="0,-0.5 0.433,0.25 -0.433,0.25" fill="#FF6347"/>
  <polygon points="0,-0.5 0.433,0.25 0,0.75" fill="#4682B4"/>
  <polygon points="0.433,0.25 -0.433,0.25 0,0.75" fill="#32CD32"/>
  <polygon points="0,-0.5 -0.433,0.25 0,0.75" fill="#FFD700"/>
</svg>
END
my $app_foo = sub {
        return [
                200,
                ['Content-Type' => 'image/svg+xml'],
                [$svg_foo],
        ];
};

# Plack application with bar SVG file.
my $svg_bar = <<'END';
<?xml version="1.0" ?>
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
  <polygon points="100,30 50,150 150,150" fill="#4682B4"/>
  <polygon points="100,30 150,150 130,170" fill="#4682B4" opacity="0.9"/>
  <polygon points="100,30 50,150 70,170" fill="#4682B4" opacity="0.9"/>
  <polygon points="70,170 130,170 100,150" fill="#4682B4" opacity="0.8"/>
</svg>
END
my $app_bar = sub {
        return [
                200,
                ['Content-Type' => 'image/svg+xml'],
                [$svg_bar],
        ];
};

my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
        'preserved' => ['style'],
);

# Navigation items.
my @items = (
        Data::Navigation::Item->new(
                'class' => 'nav-item',
                'desc' => 'This is description #1',
                'id' => 1,
                'image' => '/img/foo.svg',
                'location' => '/first',
                'title' => 'First',
        ),
        Data::Navigation::Item->new(
                'class' => 'nav-item',
                'desc' => 'This is description #2',
                'id' => 2,
                'image' => '/img/bar.svg',
                'location' => '/second',
                'title' => 'Second',
        ),
);

# Plack application for grid.
my $app_grid = Plack::App::Tags::HTML->new(
        'component' => 'Tags::HTML::Navigation::Grid',
        'data_init' => [\@items],
        'css' => $css,
        'tags' => $tags,
)->to_app;

# Runner.
my $builder = Plack::Builder->new;
$builder->mount('/img/foo.svg' => $app_foo);
$builder->mount('/img/bar.svg' => $app_bar);
$builder->mount('/' => $app_grid);
Plack::Runner->new->run($builder->to_app);

# Output screenshot is in images/ directory.