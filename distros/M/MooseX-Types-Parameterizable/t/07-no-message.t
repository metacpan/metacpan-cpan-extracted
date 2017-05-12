use strict;
use warnings;

use Test::More;

{
    package Test::MyMooseClass;

    use Moose;
    use MooseX::Types::Parameterizable qw(Parameterizable);
    use MooseX::Types::Moose qw(Str Int);
    use MooseX::Types -declare=>[qw(Varchar)];

    ## Minor change from docs to avoid additional test dependencies
    subtype Varchar,
      as Parameterizable[Str,Int],
      where {
        my($string, $int) = @_;
        $int >= length($string) ? 1:0;
      };

    has short_string => ( is => 'rw', isa => Varchar[5] );
}

my $obj = Test::MyMooseClass->new(short_string => 'four');

is $obj->short_string, 'four', 'attribute stored correctly';

# this should die
eval { $obj->short_string('longer') };

like $@, qr/Attribute \(short_string\) does not pass the type constraint/, 'fails on longer string with correct error message';

done_testing;
