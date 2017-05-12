#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;
use lib "t/springfield";

BEGIN {
    use_ok "Springfield";
};

local $/;

SKIP:
{
    my $dbh = DBI->connect( $Springfield::cs,
			    $Springfield::user,
			    $Springfield::passwd )
	or skip "could not connect to database", 1;

    $dbh->{RaiseError} = 1;

    $Springfield::dialect->retreat($Springfield::schema, $dbh);

    pass("retreat completed without raising errors");

    $dbh->disconnect;
}
