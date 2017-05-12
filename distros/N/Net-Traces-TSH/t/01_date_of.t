# Test correct operation of Net::Traces::TSH date_of()
#
use strict;
use Test;

BEGIN { plan tests => 15 };
use Net::Traces::TSH 0.13 qw( date_of );
ok(1);

ok(date_of 'AIX-1072917725-1.csv', 'Thu Jan  1 00:42:05 2004 GMT');
ok(date_of 'ANL-1073218137-1', 'Sun Jan  4 12:08:57 2004 GMT');
ok(date_of 'ANL-1073759754-1.tsh', 'Sat Jan 10 18:35:54 2004 GMT');
ok(date_of 'APN-1073122965.tsh', 'Sat Jan  3 09:42:45 2004 GMT');
ok(date_of 'BWY-1068001821-1.csv', 'Wed Nov  5 03:10:21 2003 GMT');
ok(date_of 'BWY-1073954865-1.tsh', 'Tue Jan 13 00:47:45 2004 GMT');
ok(date_of 'COS-1073737619-1.tsh', 'Sat Jan 10 12:26:59 2004 GMT');
ok(date_of 'MRA-1073717265-1.tsh', 'Sat Jan 10 06:47:45 2004 GMT');
ok(date_of 'MRA-1075238488-1.tsh', 'Tue Jan 27 21:21:28 2004 GMT');
ok(date_of 'ODU-1073132115.tsh', 'Sat Jan  3 12:15:15 2004 GMT');
ok(date_of 'TXG-1074268173-1.tsh', 'Fri Jan 16 15:49:33 2004 GMT');
ok(date_of 'sample.tsh', '');
ok(date_of 'and another random string', '');
ok(date_of '', '');

