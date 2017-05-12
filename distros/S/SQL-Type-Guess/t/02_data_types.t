#!perl -w
use strict;
use Test::More tests => 9;

use SQL::Type::Guess;

my $g= SQL::Type::Guess->new();

is $g->guess_data_type(undef, 1,2,3,1000,10), 'decimal(4,0)', 'Just whole numbers';
is $g->guess_data_type(undef, 1,2,3,1000,-10), 'decimal(4,0)', 'Just whole numbers, with negative';
is $g->guess_data_type(undef, 1,2,3,'x',-10), 'varchar(3)', 'A varchar';
is $g->guess_data_type(undef, " 1",2,"3"), 'decimal(1,0)', 'Leading whitespace is OK for numbers';
is $g->guess_data_type(undef, "1",2,"3 "), 'decimal(1,0)', 'Trailing whitespace is OK for numbers';
is $g->guess_data_type(undef, "-10",2,"+30"), 'decimal(2,0)', 'Leading sign is OK for numbers';

for my $type ('decimal(1,0)','varchar(3)', '') {
    is $g->guess_data_type($type, ''), $type, "Empty string as value does not change the type ('$type')";
};
