#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Net::NodeTransformator');
}

diag(
"Testing Net-NodeTransformator $Net::NodeTransformator::VERSION, Perl $], $^X"
);
