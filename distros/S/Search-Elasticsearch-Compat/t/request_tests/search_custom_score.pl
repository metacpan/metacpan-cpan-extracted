#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

# CUSTOM SCORE
ok $r= $es->search(
    query => {
        custom_score => {
            query => { match_all => {} },
            script => "doc['date'].date.toString() > '2010-04-25' ? 2: 1"
        }
    }
    ),
    'Custom score';
is $r->{hits}{total},     29, ' - total is 29';
is $r->{hits}{max_score}, 2,  ' - max score is 2';
is $r->{hits}{hits}[0]{_score}, 2, ' - first result scores 2';
ok $r->{hits}{hits}[0]{_source}{date} gt '2010-04-25',
    ' - first result has high date';
is $r->{hits}{hits}[-1]{_score}, 1, ' - last result scores 1';
ok $r->{hits}{hits}[-1]{_source}{date} lt '2010-04-25',
    ' - last result has low date';

1
