#!/usr/bin/env perl

use v5.36;
use Data::Dumper;

use lib 'lib';

use Test::More;

use Org::ReadTables;

my $text = '';
while (!eof(DATA)) {
    $text .= <DATA>
}

{
    my $t= Org::ReadTables->new (
        cb => sub ($table, $record) { return 1; },
        cb_table => sub ($columns) { return 1; },
    );

    $t->parse($text);
    is_deeply( $t->inserted, { 'departments' => 3,
                               'Locos' => 2,
                               'Colors' => 4,
                               'LCCN_Serial' => 4,
                               'sizes' => 19,
                           }, "Insertion count matches");
}

# Now modify the column names to database field names by removing 

{
    my $t= Org::ReadTables->new (
        cb_table => sub ($table) { foreach ($table->{columns}->@*) { s/.+\s+(\S+).*/$1/; }
                                   ${$table->{nameref}} = uc($table->{name});
                                   return 1;
                               },
    );

    $t->parse($text);

    is ($t->saved->{DEPARTMENTS}->[0]->{class}, 'C', 'Renamed table and column successfully with callback')
}

{
    my $t= Org::ReadTables->new (
        cb => sub ($table, $record) { return defined $record->{publication} && $record->{publication} =~ /d/i; },
        cb_table => sub ($table) { say STDERR "bork"; return 1; },
    );

    $t->parse($text);
    is_deeply ( $t->saved,  { 'LCCN_Serial' => [
        { 'start_date' => undef,
          'lccn' => 'sn92024097',
          'publication' => 'Adahooniłigii',
          'end_date' => undef,
          'city' => 'Phoenix'
        },
        { 'end_date' => undef,
          'publication' => 'Arizona Daily Citizen',
          'city' => 'Tucson',
          'start_date' => undef,
          'lccn' => 'sn87062098'
         } ] }, "Record selection by table name and content is ok" );
}

{
    # Read only unnamed tables.
    my $tt= Org::ReadTables->new (
        table => 'DEFAULT',
        tables => ['DEFAULT'],
    );

    $tt->parse($text);
    is_deeply ( $tt->saved, {
        'DEFAULT' => [ {'code' => 'AZ', 'state' => 'Arizona' },
                       {'code' => 'FL', 'state' => 'Florida'},
                       {'code' => 'KS', 'state' => 'Kansas'},
                       {'code' => 'MO', 'state' => 'Missouri'},
                       {'code' => 'KY', 'state' => 'Kentucky'},
                   ] } );

}

done_testing();

__END__

1;


__DATA__

* Departments
** Including mapping from each department to a size class

Demonstrates using the verbose 'drawer' format in Orgmode

:PROPERTIES:
:name:     departments
:data: foo
:temp: zap
:END:
#+PROPERTY: fixed_value "This is a fixed value  with    many    spaces"  and       such
#+CAPTION: Clothing Departments
| DEPT | P/N Prefix | Description              | size class |
|------+------------+--------------------------+------------|
|    1 | BL         | Belt                     | C          |
|    2 | BR         | Bracelet                 |            |
|    3 | BT         | Boots                    | B          |

| Code | State   |
|------+---------|
| AZ   | Arizona |
| FL   | Florida |
| KS   | Kansas  |

| Code | State    |
|------+----------|
| MO   | Missouri |
| KY   | Kentucky |

Demonstrates using the terse #+ format in Orgmode

#+NAME: Colors
| Letter | Color   |
|--------+---------|
| C      | Cyan    |
| M      | Magenta |
| Y      | Yellow  |
| K      | Black   |

#+NAME: LCCN_Serial
| LCCN       | Publication           | City    | Start_Date |   End_Date |
|------------+-----------------------+---------+------------+------------|
| sn92024097 | Adahooniłigii         | Phoenix |            |            |
| sn87062098 | Arizona Daily Citizen | Tucson  |            |            |
| sn84020558 | Arizona Republican    | Phoenix | 1890-05-19 | 1930-11-10 |
| sn83045137 | Arizona Republic      | Phoenix | 1930-11-11 |            |

# Below we test including a caption, and still picking up the Properties drawer

* Locomotives
:PROPERTIES:
:Name: Locos
:END:
#+CAPTION: Whyte Loco Notations
| Wheel Arrangement | Locomotive Type |
|-------------------+-----------------|
| oo-oo>            | American        |
| ooo-oo>           | Mogul           |

* Womens Wear Sizes
# 2025-01-06 This syntax is not yet supported!
# :PROPERTIES:
# :Name: sizes
# :Data: size_desc
# :END:
# |     class> |     A |   B |     C | D   |
# |  size_code |       |     |       |     |
# |------------+-------+-----+-------+-----|
# |          1 |   3-4 |   6 | 26-30 | XS  |
# |          2 |   5-6 | 6.5 | 30-34 | S   |
# |          3 |   7-8 |   7 | 34-36 | M   |
# |          4 |  9-10 | 7.5 | 36-40 | L   |
# |          5 | 11-12 |   8 | 40-44 | XL  |
# |          6 | 13-14 | 8.5 | 44-48 | XXL |
# |          7 | 15-16 |   9 | 48-52 | 3XL |
# |          8 | 17-18 |  10 |       |     |
# |          9 | 19-20 |  11 |       |     |
# |         10 | 21-22 |     |       |     |

# The following inserts a fixed column 'class' with value 'A' in each
# row, using the single PROPERTY syntax

#+NAME: sizes
#+PROPERTY: class A
| size_code | size_desc |
|-----------+-----------|
|         1 |       3-4 |
|         2 |       5-6 |
|         3 |       7-8 |
|         4 |      9-10 |
|         5 |     11-12 |
|         6 |     13-14 |
|         7 |     15-16 |
|         8 |     17-18 |
|         9 |     19-20 |
|        10 |     21-22 |

# And here we show using a full Drawer

#+NAME: sizes
:PROPERTIES:
:class: B
:END:
| size_code | size_desc |
|-----------+-----------|
|         1 |         6 |
|         2 |       6.5 |
|         3 |         7 |
|         4 |       7.5 |
|         5 |         8 |
|         6 |       8.5 |
|         7 |         9 |
|         8 |        10 |
|         9 |        11 |
