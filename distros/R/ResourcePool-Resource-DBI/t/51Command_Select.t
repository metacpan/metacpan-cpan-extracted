#! /usr/bin/perl -w
#*********************************************************************
#*** t/50Command_Select.t
#*** Copyright (c) 2003-2004 by Markus Winand <mws@fatalmind.com>
#*** $Id: 51Command_Select.t,v 1.2 2004/05/02 07:49:00 mws Exp $
#*********************************************************************
use strict;

use Test;
use ResourcePool;
use ResourcePool::Command::DBI::Select;
use DBI qw(:sql_types);

BEGIN {
	plan tests => 5;
}

# there shall be silence
$SIG{'__WARN__'} = sub {};

my $cmd1 = ResourcePool::Command::DBI::Select->new();
ok ($cmd1);	# worked ;)
ok (! defined ($cmd1->getSQL()));
ok (! defined ($cmd1->_getBindArgs()));
ok (defined ($cmd1->_getOptions())); # there should be a default options set
ok (! $cmd1->_getOptPrepareCached()); # default for prepare_cached is OFF

# no more tests since they are anyway tested thrugh Execute and derived from
# Common.pm
