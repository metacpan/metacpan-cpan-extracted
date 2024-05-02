#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Tags::HTML;
use Plack::Runner;
use Tags::HTML::Tree;
use Tags::Output::Indent;
use Tree;

# Example tree object.
my $data_tree = Tree->new('Root');
my %node;
foreach my $node_string (qw/H I J K L M N O P Q/) {
         $node{$node_string} = Tree->new($node_string);
}
$data_tree->add_child($node{'H'});
$node{'H'}->add_child($node{'I'});
$node{'I'}->add_child($node{'J'});
$node{'H'}->add_child($node{'K'});
$node{'H'}->add_child($node{'L'});
$data_tree->add_child($node{'M'});
$data_tree->add_child($node{'N'});
$node{'N'}->add_child($node{'O'});
$node{'O'}->add_child($node{'P'});
$node{'P'}->add_child($node{'Q'});

my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
        'preserved' => ['script', 'style'],
);
my $app = Plack::App::Tags::HTML->new(
        'component' => 'Tags::HTML::Tree',
        'data_init' => [$data_tree],
        'css' => $css,
        'tags' => $tags,
)->to_app;
Plack::Runner->new->run($app);

# Output screenshot is in images/ directory.