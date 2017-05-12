use strict;
use warnings;
use Test::More 0.89;

{
    package Foo;
    use NanoMsg::Raw;

    ::ok exists $::Foo::{NN_PAIR};
    ::ok exists $::Foo::{nn_socket};
}

{
    package Bar;
    use NanoMsg::Raw ':constants';

    ::ok exists $::Bar::{NN_PAIR};
    ::ok !exists $::Bar::{nn_socket};
}

{
    package Baz;
    use NanoMsg::Raw ':functions';

    ::ok !exists $::Baz::{NN_PAIR};
    ::ok exists $::Baz::{nn_socket};
}

{
    package Moo;
    use NanoMsg::Raw ':all';

    ::ok exists $::Foo::{NN_PAIR};
    ::ok exists $::Foo::{nn_socket};
}

done_testing;
