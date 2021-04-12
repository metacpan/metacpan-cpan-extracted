#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use TableData::Test::Angka;

my $t = TableData::Test::Angka->new;
is($t->as_csv, <<_);
number,en_name,id_name
1,one,satu
2,two,dua
3,three,tiga
4,four,empat
5,five,lima
_

is($t->get_column_count, 3);
is_deeply([$t->get_column_names], [qw/number en_name id_name/]);
$t->reset_row_iterator;
is_deeply($t->get_row_arrayref, [qw/1 one satu/]);
is_deeply($t->get_row_hashref , {number=>2, en_name=>"two", id_name=>"dua"});
is_deeply($t->get_row_arrayref, [qw/3 three tiga/]);
$t->reset_row_iterator;
is_deeply($t->get_row_hashref , {number=>1, en_name=>"one", id_name=>"satu"});
is($t->get_row_count, 5);

done_testing;
