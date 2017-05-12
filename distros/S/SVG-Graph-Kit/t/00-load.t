#!perl -T
use strict;
use warnings;
use Test::More;
use_ok 'SVG::Graph::Kit';
diag(sprintf 'Testing SVG::Graph::Kit %s, Perl %s, %s with SVG::Graph version %s',
    $SVG::Graph::Kit::VERSION, $], $^X, $SVG::Graph::VERSION
);
done_testing();
