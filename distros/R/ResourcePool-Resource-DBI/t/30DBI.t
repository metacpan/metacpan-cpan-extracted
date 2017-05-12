#! /usr/bin/perl -w
#*********************************************************************
#*** t/30DBI.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 30DBI.t,v 1.1 2002/12/22 11:20:44 mws Exp $
#*********************************************************************
use strict;

use Test;

BEGIN {
	use ResourcePool;
	eval "use DBI; use ResourcePool::Factory::DBI;";
	plan tests => 2;
}

if (!exists $INC{"DBI.pm"}) {
	skip("skip DBI not found", 0);
	skip("skip DBI not found", 0);
	exit(0);
}

# there shall be silence
$SIG{'__WARN__'} = sub {};

my $f1 = ResourcePool::Factory::DBI->new("DataSource1", "user", "pass");
my $pr1 = $f1->create_resource();
ok(! defined $pr1);

my $f2 = ResourcePool::Factory::DBI->new("DataSource2", "user", "pass", {RaiseError => 1});
my $pr2 = $f2->create_resource();
ok(! defined $pr2);


