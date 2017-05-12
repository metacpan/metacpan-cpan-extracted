use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 8;

use Banana::Tree;
use Orchard::Tree::Pear::Conference;

use Sub::WrapPackages (
    packages => [qw(Banana::Tree Orchard::*)],
    pre      => sub {
        ok(1, "$_[0] pre-wrapper")
    },
    post     => sub {
        ok(1, "$_[0] post-wrapper")
    }
);

ok(Orchard::Tree::Pear::Conference::tastes_nasty, "Conference pears are BAD");
Banana::Tree::foo();
