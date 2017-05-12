package TAEB::Test::Items;
use TAEB::Test;
use List::Util 'sum';

sub import {
    my $self = shift;

    main->import('Test::More');

    plan_tests(@_);
    test_items(@_);
}

1;

