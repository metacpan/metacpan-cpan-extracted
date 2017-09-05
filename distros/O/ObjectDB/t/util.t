use strict;
use warnings;

use Test::More;

use ObjectDB::Util qw/to_array filter_columns/;

subtest 'to_array: converts data to array' => sub {
    is_deeply [to_array],        [];
    is_deeply [ to_array(1) ],   [1];
    is_deeply [ to_array([1]) ], [1];
    is_deeply [ to_array([ 1, 2 ]) ], [ 1, 2 ];
};

subtest 'filter_columns: filters columns' => sub {
    is_deeply filter_columns([qw/title/]), [qw/title/];
    is_deeply filter_columns([qw/title/],      { columns    => [qw/custom/] }), [qw/custom/];
    is_deeply filter_columns([qw/title/],      { '+columns' => [qw/custom/] }), [qw/title custom/];
    is_deeply filter_columns([qw/title long/], { '-columns' => [qw/long/] }),   [qw/title/];
};

done_testing;
