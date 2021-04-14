#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use TableData::Test::Source::CSVDATA;

my $table = TableData::Test::Source::CSVDATA->new;
Role::Tiny->apply_roles_to_object($table, 'TableDataRole::Util::CSV');

subtest "as_csv" => sub {
    is($table->as_csv, <<'_');
number,en_name,id_name
1,one,satu
2,two,dua
3,three,tiga
4,four,empat
5,five,lima
_
};

done_testing;
