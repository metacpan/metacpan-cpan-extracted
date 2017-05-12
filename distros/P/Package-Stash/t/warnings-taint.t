#!/usr/bin/env perl -T
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Package::Stash;

my $warnings;
BEGIN {
    $warnings = '';
    $SIG{__WARN__} = sub { $warnings .= $_[0] };
}

BEGIN {
    my $stash = Package::Stash->new('Foo');
    $stash->get_or_add_symbol('$bar');
}

is($warnings, '');

done_testing;
