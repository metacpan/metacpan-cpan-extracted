#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Stash::Manip;

{
    my $stash = Stash::Manip->new('Foo');
    my $val = $stash->get_package_symbol('%foo');
    is(ref($val), 'HASH', "got something");
    $val->{bar} = 1;
    is_deeply($stash->get_package_symbol('%foo'), {bar => 1},
              "got the right variable");
}

{
    my $stash = Stash::Manip->new('Bar');
    my $val = $stash->get_package_symbol('@foo');
    is(ref($val), 'ARRAY', "got something");
    push @$val, 1;
    is_deeply($stash->get_package_symbol('@foo'), [1],
              "got the right variable");
}

done_testing;
