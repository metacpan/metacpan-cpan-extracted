use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 6;

use Sub::WrapPackages (
    packages => [qw(Banana::Tree Orchard::*)],
    except   => qr/(::foo)$/,
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
