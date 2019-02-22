#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

my $table = bless(
  {
    'rows' => [
      ['1',  '123'],
      ['12', '1234'],
    ],
  },
  $CLASS
);

$table->{'header'} = ['header 0', 'header 12'];
is($table->_max_column_width(0), 8, 'Header value length taken over');

$table->{'header'} = [];
is($table->_max_column_width(0), 2, 'Table column width taken over');

done_testing();