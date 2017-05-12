#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# XXX: work around dumb core segfault bug when you delete stashes
sub get_impl { eval '$Package::Stash::IMPLEMENTATION' }
sub set_impl { eval '$Package::Stash::IMPLEMENTATION = "' . $_[0] . '"' }

{
    $ENV{PACKAGE_STASH_IMPLEMENTATION} = 'PP';
    require Package::Stash;
    is(get_impl, 'PP', "autodetected properly: PP");
    can_ok('Package::Stash', 'new');
}

delete $Package::{'Stash::'};
delete $INC{'Package/Stash.pm'};
delete $INC{'Package/Stash/PP.pm'};

SKIP: {
    skip "no XS", 2 unless eval "require Package::Stash::XS; 1";
    $ENV{PACKAGE_STASH_IMPLEMENTATION} = 'XS';
    require Package::Stash;
    is(get_impl, 'XS', "autodetected properly: XS");
    can_ok('Package::Stash', 'new');
}

{
    delete $Package::{'Stash::'};
    delete $INC{'Package/Stash.pm'};
    set_impl('INVALID');
    $ENV{PACKAGE_STASH_IMPLEMENTATION} = 'PP';
    require Package::Stash;
    is(get_impl, 'PP', '$ENV takes precedence over $Package::Stash::IMPLEMENTATION');
    can_ok('Package::Stash', 'new');
}

done_testing;
