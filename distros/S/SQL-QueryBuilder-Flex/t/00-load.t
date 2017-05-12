
use lib qw( lib );
use strict;
use warnings;

use Test::More tests => 2;

my $package = 'SQL::QueryBuilder::Flex';
use_ok($package);

can_ok($package, qw/
    parent
    get_writer
    set_writer
    build
    do_build
    to_sql
    options
    select
    update
    union
    insert
    set
    get_query
    from
    where
    having
    group_by
    order_by
    order_by_asc
    order_by_desc
    limit
    offset
    inner_join
    left_join
    right_join
    clear_options
    clear_select
    clear_from
    clear_join
    clear_where
    clear_having
    clear_order_by
    clear_group_by
    delete_column
    delete_from
    delete_join
/);

diag( "Testing SQL::QueryBuilder::Flex $SQL::QueryBuilder::Flex::VERSION, Perl $], $^X" );
