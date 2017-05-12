#!/usr/bin/perl

use Test::More tests => 8;

BEGIN { use_ok( 'ORM::Date' ); }

ok( ORM::Date->new( [2004,9, 1,10,0,0] )->mysql_datetime eq '2004-09-01 10:00:00', 'Daylight saving time' );
ok( ORM::Date->new( [2004,10,1,10,0,0] )->mysql_datetime eq '2004-10-01 10:00:00', 'Daylight saving time' );
ok( ORM::Date->new( [2004,11,1,10,0,0] )->mysql_datetime eq '2004-11-01 10:00:00', 'Daylight saving time' );
ok( ORM::Date->new( [2005,3, 1,10,0,0] )->mysql_datetime eq '2005-03-01 10:00:00', 'Daylight saving time' );
ok( ORM::Date->new( [2005,4, 1,10,0,0] )->mysql_datetime eq '2005-04-01 10:00:00', 'Daylight saving time' );
ok( ORM::Date->new( [2005,1,15,-1,0,0] )->mysql_datetime eq '2005-01-14 23:00:00', 'Outbound ranges' );

#ORM::Date->use_utc_tz;
#ok( ORM::Date->new( [2005,1,15,-1,0,0] )->mysql_datetime eq '2005-01-14 18:00:00', 'Use UTC' );

ORM::Date->use_local_tz;
ok( ORM::Date->new( [2005,1,15,-1,0,0] )->mysql_datetime eq '2005-01-14 23:00:00', 'Use local timezone' );
