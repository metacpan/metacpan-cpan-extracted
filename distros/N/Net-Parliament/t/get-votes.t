#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;

use_ok 'Net::Parliament';

my $np = Net::Parliament->new( parliament => 39, session => 2 );
isa_ok $np, 'Net::Parliament';

Bill_votes: {
    my $votes = $np->bill_votes('C-2');
    my $vote = shift @$votes;
    is_deeply $vote, {
        'TotalNays' => '1',
        'number' => '15',
        'parliament' => '39',
        'TotalYeas' => '221',
        'Decision' => 'Agreed to',
        'date' => '2007-11-26',
        'TotalPaired' => '0',
        'session' => '2',
        'RelatedBill' => {
            'number' => 'C-2'
        },
        'sitting' => '24',
        'Description' => 'Concurrence at report stage of Bill C-2, An Act to amend the Criminal Code and to make consequential amendments to other Acts',
    };
}


Member_votes: {
    my $votes = $np->member_votes(78755);
    my $vote = shift @$votes;
    is_deeply $vote, {
        'TotalNays'    => '64',
        'number'       => '157',
        'parliament'   => '39',
        'TotalYeas'    => '185',
        'Decision'     => 'Agreed to',
        'date'         => '2008-06-17',
        'TotalPaired'  => '0',
        'session'      => '2',
        'RelatedBill'  => { 'number' => 'C-29' },
        'RecordedVote' => {
            'Paired' => '0',
            'Nay'    => '0',
            'Yea'    => '1'
        },
        'sitting' => '114',
        'Description' => '3rd reading and adoption of Bill C-29, An Act to amend the Canada Elections Act (accountability with respect to loans)',
    };
}
