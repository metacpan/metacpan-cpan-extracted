#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

{
    package Test::AutoImmute;
    use strict;
    use warnings;
    use MooseX::AutoImmute;

    has thing => (
        isa => 'Str',
        is => 'rw',
    );

    1;
}

ok( Test::AutoImmute->meta->is_immutable, "Autamatically Immutable" );

done_testing();
