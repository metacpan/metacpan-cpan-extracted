#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;

use_ok 'Net::Parliament';

my $np = Net::Parliament->new( parliament => 39, session => 2 );
isa_ok $np, 'Net::Parliament';

my $bills = $np->bills();
my $bill = shift @$bills;
is_deeply $bill, {
    name => 'C-2',
    summary => 'An Act to amend the Criminal Code and to make consequential '
               . 'amendments to other Acts',
    sponsor_title => 'The Minister of Justice',
    sponsor_id => 105824,
    parliament => 39,
    session => 2,
    links => [
        {
            'Legislative Summary' => 'http://www2.parl.gc.ca/HouseBills/StaticLinkRedirector.aspx?Language=e&LinkTitle=(C-2)%20Legislative%20Summary&RedirectUrl=%2fSites%2fLOP%2fLEGISINFO%2findex.asp%3fList%3dls%26Language%3dE%26Query%3d5273%26Session%3d15&RefererUrl=X&StatsEnabled=true',
        },
        {
            'First Reading' => 'http://www2.parl.gc.ca/HousePublications/Publication.aspx?DocId=3078412&Language=e&Mode=1',
        },
        {
            'As passed by the House of Commons' => 'http://www2.parl.gc.ca/HousePublications/Publication.aspx?DocId=3151626&Language=e&Mode=1',
        },
        {
            'Royal Assent' => 'http://www2.parl.gc.ca/HousePublications/Publication.aspx?DocId=3320180&Language=e&Mode=1',
        },
        {
            'Votes' => 'http://www2.parl.gc.ca/housebills/BillVotes.aspx?Language=e&Mode=1&Parl=39&Ses=2&Bill=C2',
        },
    ],
}, 'Bill C-2';

$bill = shift @$bills;
is_deeply $bill, {
    name => 'C-3',
    parliament => 39,
    session => 2,
    summary => 'An Act to amend the Immigration and Refugee Protection Act '
               . '(certificate and special advocate) and to make a '
               . 'consequential amendment to another Act',
    sponsor_title => 'The Minister of Public Safety',
    sponsor_id => 78755,
    links => [
        {
            'Legislative Summary' => 'http://www2.parl.gc.ca/HouseBills/StaticLinkRedirector.aspx?Language=e&LinkTitle=(C-3)%20Legislative%20Summary&RedirectUrl=%2fSites%2fLOP%2fLEGISINFO%2findex.asp%3fList%3dls%26Language%3dE%26Query%3d5278%26Session%3d15&RefererUrl=X&StatsEnabled=true',
        },
        {
            'First Reading' => 'http://www2.parl.gc.ca/HousePublications/Publication.aspx?DocId=3081183&Language=e&Mode=1',
        },
        {
            'Reprinted as amended by the Standing Committee' => 'http://www2.parl.gc.ca/HousePublications/Publication.aspx?DocId=3196798&Language=e&Mode=1',
        },
        {
            'As passed by the House of Commons' => 'http://www2.parl.gc.ca/HousePublications/Publication.aspx?DocId=3251971&Language=e&Mode=1',
        },
        {
            'Royal Assent' => 'http://www2.parl.gc.ca/HousePublications/Publication.aspx?DocId=3300375&Language=e&Mode=1',
        },
        {
            'Votes' => 'http://www2.parl.gc.ca/housebills/BillVotes.aspx?Language=e&Mode=1&Parl=39&Ses=2&Bill=C3',
        },
    ],
}, 'Bill C-3';
