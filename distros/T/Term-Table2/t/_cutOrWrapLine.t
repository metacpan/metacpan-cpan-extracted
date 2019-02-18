#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

my $table = bless({'table_width' => 5}, $CLASS);

$table->{':splitOffset'} = 2;
$table->{'broad_row'}    = WRAP;
is([$table->_cutOrWrapLine('0123456789')], ['23456', '789'], 'Non-zero offset, line is too long and must be wrapped');

$table->{':splitOffset'} = 0;
$table->{'broad_row'}    = CUT;
is([$table->_cutOrWrapLine('0123456789')], ['01234'],        'Non-zero offset, line is too long and must be cut off');

$table->{':splitOffset'} = 0;
$table->{'broad_row'}    = WRAP;
is([$table->_cutOrWrapLine('012')],        ['012'],          'Non-zero offset, line is not too long');

done_testing();