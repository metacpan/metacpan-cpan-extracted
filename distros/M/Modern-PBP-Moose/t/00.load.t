use Test::More tests => 1;
{
   package Test::Moose;
   use strict;
   use warnings;
   use Modern::PBP::Moose;
   has thing => (
        isa => 'Str',
        is => 'rw',
    );
   1;
}

ok( Test::Moose->meta->is_immutable, "Autamatically Immutable" );

done_testing();
