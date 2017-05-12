#!/usr/bin/env perl

use utf8;
use 5.014;
use warnings;
use open qw/:encoding(UTF-8) :std/;

use Test::More;

BEGIN {
    use_ok('No::OrgNr');
}

can_ok( 'No::OrgNr', 'domain2orgnr' );
can_ok( 'No::OrgNr', 'num_domains' );
can_ok( 'No::OrgNr', 'orgnr_ok' );
can_ok( 'No::OrgNr', 'orgnr2domains' );

done_testing;
