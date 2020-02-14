#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 22;

use_ok 'SQL::OrderBy';

# fetch a numeric name_direction list
my @columns = SQL::OrderBy::get_columns(
    order_by => [],
);
is scalar @columns, 0, 'empty column array';
@columns = SQL::OrderBy::get_columns(
    order_by => '',
);
is scalar @columns, 0, 'empty column string';

# fetch a numeric name_direction list
@columns = SQL::OrderBy::get_columns(
    order_by => 'name, artist desc, album',
    show_ascending    => 1,
    name_direction    => 1,
    numeric_direction => 1,
);
is join(', ', @{ $columns[0] }),
    'name, artist, album',
    'column name list';
is join(', ', map { $columns[1]->{$_} } sort keys %{ $columns[1] }),
    '1, 0, 1',
    'numeric column directions';
is join(', ', map { $columns[2]->{$_} } sort keys %{ $columns[2] }),
    ', desc, ',
    'passed alpha column directions';

# fetch a asc/desc name_direction list
# NOTE: Original case of asc/DESC is not preserved. Oops!
@columns = SQL::OrderBy::get_columns(
    order_by => 'Name, Artist Desc, Album',
    show_ascending => 1,
    name_direction => 1,
);
is join(', ', map { "$_ $columns[1]->{$_}" } sort keys %{ $columns[1] }),
    'Album asc, Artist Desc, Name asc',
    'asc/desc column directions';

# convert column directions
my %direction = (NAME => 1, ARTIST => 0, ALBUM => 1);
%direction = SQL::OrderBy::to_asc_desc(
    \%direction,
    uc_direction => 1,
);
is join (', ', map { $direction{$_} ? "$_ $direction{$_}" : $_ } sort keys %direction),
    'ALBUM, ARTIST DESC, NAME',
    'numeric column directions to hidden ASC/DESC';
%direction = (name => 1, artist => 0, album => 1);
%direction = SQL::OrderBy::to_asc_desc(
    \%direction,
    show_ascending => 1,
);
is join (', ', map { $direction{$_} ? "$_ $direction{$_}" : $_ } sort keys %direction),
    'album asc, artist desc, name asc',
    'numeric column directions to exposed asc/desc';

# render a column name direction list
%direction = (name => 'asc', artist => 'desc', album => 'asc');
@columns = SQL::OrderBy::col_dir_list([qw(name artist album)], \%direction);
is join(', ', @columns), 'name asc, artist desc, album asc',
    'column name direction list rendered';

# fetch column names with exposed direction
# in array context
@columns = SQL::OrderBy::get_columns(
    order_by => 'name, artist desc, album',
    show_ascending => 1,
);
is join(', ', @columns), 'name asc, artist desc, album asc',
    'column names with exposed asc in array context';
# in scalar context
my $columns = SQL::OrderBy::get_columns(
    order_by => ['name', 'artist desc', 'album'],
    show_ascending => 1,
);
is $columns, 'name asc, artist desc, album asc',
    'column names with exposed asc in scalar context';

# fetch column names with hidden asc
# in array context
@columns = SQL::OrderBy::get_columns(
    order_by => 'name asc, artist desc, album',
);
is join(', ', @columns), 'name, artist desc, album',
    'column names with hidden asc in array context';
# in scalar context
$columns = SQL::OrderBy::get_columns(
    order_by => ['name', 'artist desc', 'album'],
);
is $columns, 'name, artist desc, album',
    'column names with hidden asc in scalar context';

# toggle in scalar context
my $order = SQL::OrderBy::toggle_resort(
    selected => 'artist',
    order_by => [ qw(name artist album) ],
);
is $order, 'artist, name, album',
    'order array in scalar context';
$order = SQL::OrderBy::toggle_resort(
    selected => 'artist',
    order_by => 'name, artist, album',
);
is $order, 'artist, name, album',
    'order clause in scalar context';

# toggle in array context
my @order = SQL::OrderBy::toggle_resort(
    selected => 'artist',
    order_by => [ qw(name artist album) ],
);
is join (', ', @order), 'artist, name, album',
    'order array in array context';
@order = SQL::OrderBy::toggle_resort(
    selected => 'artist',
    order_by => 'name, artist, album',
);
is join (', ', @order), 'artist, name, album',
    'order clause in array context';

# toggle unseen column name with blank order-by
$order = SQL::OrderBy::toggle_resort(
    selected => 'time',
    order_by => '',
);
is $order, 'time',
    'unseen column with blank order clause';
# toggle unseen column name and direction with blank order-by
$order = SQL::OrderBy::toggle_resort(
    selected => 'time desc',
    order_by => '',
);
is $order, 'time desc',
    'unseen column and direction in blank order clause';

# exposed asc nested toggle
$order = SQL::OrderBy::toggle_resort(
    show_ascending => 1,
    selected => 'time',
    order_by => scalar SQL::OrderBy::toggle_resort(
        selected => 'artist',
        order_by => scalar SQL::OrderBy::toggle_resort(
            selected => 'artist',
            order_by => 'name, artist, album',
        )
    )
);
is $order, 'time asc, artist desc, name asc, album asc',
    'exposed asc nested transformation';

# hidden asc nested toggle
$order = SQL::OrderBy::toggle_resort(
    selected => 'time',
    order_by => scalar SQL::OrderBy::toggle_resort(
        selected => 'artist',
        order_by => scalar SQL::OrderBy::toggle_resort(
            selected => 'artist',
            order_by => 'name asc, artist asc, album asc',
        )
    )
);
is $order, 'time, artist desc, name, album',
    'hidden asc nested transformation';
