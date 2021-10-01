#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use TableData::Test::Source::CSVInFiles;

my $t = TableData::Test::Source::CSVInFiles->new;
is($t->as_csv, <<_);
id,eng_word,ind_word
1,correct,benar
2,incorrect,salah
3,plenty,banyak
4,rare,jarang
5,rotten,busuk
6,tomato,tomat
7,mosque,mesjid
8,swan,angsa
9,hat,topi
10,cat,kucing
11,suddenly,tiba-tiba
12,merely,hanya
13,already,sudah
14,almost,hampir
15,eventually,akhirnya
_

is($t->get_column_count, 3);
is_deeply([$t->get_column_names], [qw/id eng_word ind_word/]);
$t->reset_iterator;
is_deeply($t->get_next_item, [qw/1 correct benar/]);
is_deeply($t->get_next_row_hashref , {id=>2, eng_word=>"incorrect", ind_word=>"salah"});
is_deeply($t->get_next_row_arrayref, [qw/3 plenty banyak/]);
$t->reset_iterator;
is_deeply($t->get_next_row_hashref , {id=>1, eng_word=>"correct", ind_word=>"benar"});
is($t->get_row_count, 15);

done_testing;
