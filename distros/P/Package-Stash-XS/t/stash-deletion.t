#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Package::Stash;

{
    package Gets::Deleted;
    sub bar { }
}

{
    my $delete = Package::Stash->new('Gets::Deleted');
    ok($delete->has_symbol('&bar'), "sees the method");
    {
        no strict 'refs';
        delete ${'main::Gets::'}{'Deleted::'};
    }
    ok(!$delete->has_symbol('&bar'), "method goes away when stash is deleted");
}

done_testing;
