#! /usr/bin/perl -w
#*********************************************************************
#*** t/30DBI.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 30Alzabo.t,v 1.1 2004/04/15 20:44:02 jgsmith Exp $
#*********************************************************************
use strict;

use Test;

BEGIN {
	use ResourcePool;
	eval "use Alzabo::Runtime::Schema; use ResourcePool::Factory::Alzabo;";
	plan tests => 2;
}

if (!exists $INC{"Alzabo/Runtime/Schema.pm"}) {
	skip("skip Alzabo not found", 0);
	skip("skip Alzabo not found", 0);
	exit(0);
}

# there shall be silence
$SIG{'__WARN__'} = sub {};

my $f1 = ResourcePool::Factory::Alzabo->new("Schema", "DataSource1", "user", "pass");
my $pr1 = $f1->create_resource();
ok(! defined $pr1);

my $f2 = ResourcePool::Factory::Alzabo->new("Schema", "DataSource2", "user", "pass", {RaiseError => 1});
my $pr2 = $f2->create_resource();
ok(! defined $pr2);


