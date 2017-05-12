use strict;
use warnings;

use lib 't/lib';

# FIXME uncomment, and fix prototype problems
# BEGIN { $SIG{__WARN__} = sub { die(@_) }; }

use Test::More tests => 8;

use Sub::WrapPackages (
    packages => [qw(Banana::Tree Orchard::*)],
    pre      => sub {
        ok(1, "$_[0] pre-wrapper")
    },
    post     => sub {
        ok(1, "$_[0] post-wrapper")
    }
);

use Banana::Tree; # load after Sub::WrapPackages
use Orchard::Tree::Pear::Conference;

ok(Orchard::Tree::Pear::Conference::tastes_nasty, "Conference pears are BAD");
Banana::Tree::foo();
