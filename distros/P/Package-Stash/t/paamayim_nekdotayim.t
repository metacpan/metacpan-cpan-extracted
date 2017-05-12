#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Fatal;

use Package::Stash;

my $stash = Package::Stash->new('Foo');
# this segfaulted on the xs version
like(
    exception { $stash->add_symbol('@bar::baz') },
    qr/^Variable names may not contain ::/,
    "can't add symbol with ::"
);
like(
    exception { $stash->get_symbol('@bar::baz') },
    qr/^Variable names may not contain ::/,
    "can't add symbol with ::"
);
like(
    exception { $stash->get_or_add_symbol('@bar::baz') },
    qr/^Variable names may not contain ::/,
    "can't add symbol with ::"
);

done_testing;
