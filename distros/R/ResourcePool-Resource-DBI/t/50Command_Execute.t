#! /usr/bin/perl -w
#*********************************************************************
#*** t/50Command_Execute.t
#*** Copyright (c) 2003-2004 by Markus Winand <mws@fatalmind.com>
#*** $Id: 50Command_Execute.t,v 1.2 2004/05/02 07:49:00 mws Exp $
#*********************************************************************
use strict;

use Test;
use ResourcePool;
use ResourcePool::Command::DBI::Execute;
use DBI qw(:sql_types);

BEGIN {
	plan tests => 30;
}

# there shall be silence
$SIG{'__WARN__'} = sub {};

my $cmd1 = ResourcePool::Command::DBI::Execute->new();
ok ($cmd1);	# worked ;)
ok (! defined ($cmd1->getSQL()));
ok (! defined ($cmd1->_getBindArgs()));
ok (defined ($cmd1->_getOptions())); # there should be a default options set
ok (! $cmd1->_getOptPrepareCached()); # default for prepare_cached is OFF

$cmd1 = ResourcePool::Command::DBI::Execute->new(prepare_cached => 1);
ok ($cmd1);	# worked ;)
ok (! defined ($cmd1->getSQL()));
ok (! defined ($cmd1->_getBindArgs()));
ok (defined ($cmd1->_getOptions())); # there should be a default options set
ok ($cmd1->_getOptPrepareCached()); # default for prepare_cached is OFF

$cmd1 = ResourcePool::Command::DBI::Execute->new('select hirsch from elch');
ok ($cmd1);	# worked ;)
ok ($cmd1->getSQL() eq 'select hirsch from elch');
ok (! defined ($cmd1->_getBindArgs()));
ok (defined ($cmd1->_getOptions())); # there should be a default options set
ok (! $cmd1->_getOptPrepareCached()); # default for prepare_cached is OFF

$cmd1 = ResourcePool::Command::DBI::Execute->new('select hirsch from elch', prepare_cached => 1);
ok ($cmd1);	# worked ;)
ok ($cmd1->getSQL() eq 'select hirsch from elch');
ok (! defined ($cmd1->_getBindArgs()));
ok (defined ($cmd1->_getOptions())); # there should be a default options set
ok ($cmd1->_getOptPrepareCached());

$cmd1 = ResourcePool::Command::DBI::Execute->new(
		  'select hirsch from elch where x = ?'
		, {1 => {type => SQL_INTEGER}}
);
ok ($cmd1);	# worked ;)
ok ($cmd1->getSQL() eq 'select hirsch from elch where x = ?');
ok ($cmd1->_getBindArgs()->{1} = SQL_INTEGER);
ok (defined ($cmd1->_getOptions())); # there should be a default options set
ok (!$cmd1->_getOptPrepareCached());

$cmd1 = ResourcePool::Command::DBI::Execute->new(
		  'select hirsch from elch where x = ?'
		, {1 => {type => SQL_INTEGER}}
		, prepare_cached => 1
);
ok ($cmd1);	# worked ;)
ok ($cmd1->getSQL() eq 'select hirsch from elch where x = ?');
ok ($cmd1->_getBindArgs()->{1} = SQL_INTEGER);
ok (defined ($cmd1->_getOptions())); # there should be a default options set
ok ($cmd1->_getOptPrepareCached());


