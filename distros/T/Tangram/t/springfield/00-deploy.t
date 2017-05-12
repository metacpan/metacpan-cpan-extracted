#!/usr/bin/perl -w

use strict;
use lib "t";
use TestNeeds qw(Test::More Set::Object);

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

    do {
	local $dbh->{PrintError};
	local $dbh->{RaiseError};
	$Springfield::dialect->retreat($Springfield::schema, $dbh);
    };

    $dbh->{RaiseError} = 1;

    $Springfield::dialect->deploy($Springfield::schema, $dbh);

    pass("deploy completed without raising errors");

    $dbh->disconnect;
}
