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

if (0) {
    my $t= Org::ReadTables->new (tables => ['pivot-test']);

    $t->parse($text);
    use Data::Dumper;
    is_deeply( $t->inserted, { 'pivot-test' => 8,
                           }, "Insertion count matches");
}

{
    my $t= Org::ReadTables->new (tables => ['pivot-3-timetable']);

    $t->parse($text);

    is_deeply( $t->saved('pivot-3-timetable'),
               [ { traintime => '3:42p',
                   station => 'Chicago',
                   Train_no => '21'
               },
                 { traintime => '4:50p',
                   station => 'Joliet',
                   Train_no => '21'
               }
             ]);
    is_deeply( $t->secondary('pivot-3-timetable'),
               {  'train_no' => { 3 => {'train_name' => 'Southwest Chief'},
                                  4 => {'train_name' => 'Southwest Chief'},
                                  21 => {'train_name' => 'Texas Eagle'},
                                  22 => {'train_name' => 'Texas Eagle'},
                               }
              });

}

done_testing();

__END__

1;


__DATA__

* An example Pivot table

The 'data' property determines the column name to insert the pivoted data into.  See this module‘s README.

:PROPERTIES:
:name: pivot-test
:data: size_desc
:END:
|     class> |     A |   B   |  C  |           |
|  size_code |       |       |     | something |
|------------+-------+-------+-----+-----------|
|          1 |   1-2 | 22-26 |     | abc       |
|          2 |   3-4 | 26-30 | XS  | def       |
|          3 |   5-6 | 30-34 | S   | ghi       |

The below illustrates a future extension to allow *two* output tables
to be defined at once.  Here, the output will have a (TBD) secondary
table as:
  class => { 'A'=>{class_name=>'Toddlers'},
             'B'=>{class_name=>'Mens'}...  }

:PROPERTIES:
:name: pivot-2
:data: size_desc
:END:
|      class> |        A |     B | C      |           |
|   size_code |          |       |        | something |
| class_name> | Toddlers |  Mens | Womens |           |
|-------------+----------+-------+--------+-----------|
|           1 |      1-2 | 22-26 |        | abc       |
|           2 |      3-4 | 26-30 | XS     | def       |
|           3 |      5-6 | 30-34 | S      | ghi       |

This illustrates how such can be used to describe a classic railroad
timetable, along with demonstrating how a title row can have
continuation rows (content will be appended, separated by spaces):

:PROPERTIES:
:name: pivot-3-timetable
:data: traintime
:END:
| Train_no>   | 21    | 22    | 3         | 4         |
| Train_name> | Texas | Texas | Southwest | Southwest |
| Train_name> | Eagle | Eagle | Chief     | Chief     |
| Station     |       |       |           |           |
|-------------+-------+-------+-----------+-----------|
| Chicago     | 3:42p |       |           |           |
| Joliet      | 4:50p |       |           |           |
| St. Louis   |       |       |           |           |
| Fort Worth  |       |       |           |           |
| Los Angeles |       |       |           |           |
