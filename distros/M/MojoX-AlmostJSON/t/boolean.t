use strict;
use warnings;
use Test::More;

use MojoX::AlmostJSON qw(encode_json true false);

my $obj = [ true, false ];
my $got = encode_json( $obj );

is $got, '[true,false]',
    'serialize booleans';

done_testing;