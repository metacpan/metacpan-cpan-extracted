#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use TableData::Munge::Concat;

my $t = TableData::Munge::Concat->new(tabledatalist => [
    'Test::Source::CSVInFile',
    'Test::Source::CSVInFile::Select=which,2',
]);

is($t->get_column_count, 3);
is_deeply([$t->get_column_names], [qw/id eng_word ind_word/]);
$t->reset_iterator;
is_deeply($t->get_next_item, [1,"correct","benar"]);
is_deeply($t->get_next_row_hashref , {id=>2,eng_word=>"incorrect",ind_word=>"salah"});
$t->get_next_item for 3..5;
is_deeply($t->get_next_row_hashref , {id=>6,eng_word=>"tomato",ind_word=>"tomat"});
$t->reset_iterator;
is_deeply($t->get_next_row_hashref , {id=>1,eng_word=>"correct",ind_word=>"benar"});
is($t->get_row_count, 10);

done_testing;
