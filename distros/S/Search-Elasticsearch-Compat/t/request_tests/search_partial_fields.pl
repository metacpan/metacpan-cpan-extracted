#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

# FIELDS
ok $r= $es->search(
    partial_fields => {
        foo => { include => 'text' },
        bar => { exclude => 'num' }
    }
    )->{hits}{hits}[0]{fields},
    'Partial fields query';
ok $r->{foo}{text}, ' - foo has text';
ok !$r->{foo}{date}, ' - foo no date';
ok $r->{bar}{date}, ' - bar has date';
ok !$r->{bar}{num}, ' - bar no num';

1
