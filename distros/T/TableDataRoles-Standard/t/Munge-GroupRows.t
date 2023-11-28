#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use TableData::Munge::GroupRows;

my $t;
{
    my $prev_year;
    $t = TableData::Munge::GroupRows->new(
        tabledata => 'Sample::DeNiro',
        key => 'year',
        calc_key => sub {
            my ($rowh, $aoa) = @_;
            if (!$prev_year) {
                $prev_year = $rowh->{Year};
            } elsif ($prev_year != $rowh->{Year}) {
                # close year gaps with empty rows
                for ($prev_year+1 .. $rowh->{Year}-1) {
                    push @$aoa, [$_, []];
                }
                $prev_year = $rowh->{Year};
            }
            $rowh->{Year};
        },
    );
}

is($t->get_column_count, 2);
is_deeply([$t->get_column_names], [qw/year rows/]);
$t->reset_iterator;
is_deeply($t->get_item_at_pos(0), [1968, [ [1968,86,'Greetings'] ]]);
is_deeply($t->get_item_at_pos(1), [1969, [ ]]);
is_deeply($t->get_item_at_pos(2), [1970, [ [1970,17,'Bloody Mama'], [1970,73,'Hi,Mom!'] ]]);
is($t->get_row_count, 49);

done_testing;
