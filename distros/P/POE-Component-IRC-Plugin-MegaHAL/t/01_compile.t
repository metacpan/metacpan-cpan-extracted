use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 2;
use Test::Script;
use_ok 'POE::Component::IRC::Plugin::MegaHAL';

SKIP: {
    skip "There's no blib", 1 unless -d "blib" and -f catfile qw(blib script irchal-seed);
    script_compiles(catfile('bin', 'irchal-seed'));
};
