use strict;
$^W = 1; 
use Test::More tests => 3;

use_ok('Sys::AlarmCall', "alarm_call");

is(alarm_call(1,'select',undef,undef,undef,10),  'TIMEOUT', 'select example - timeout');
isnt(alarm_call(2,'select',undef,undef,undef,1), 'TIMEOUT', 'select example - no timeout');



__END__

#$Apache::DBI::DEBUG = 10;

SKIP: {
  skip "Could not load DBD::mysql", 6 unless $dbd_mysql;

  ok($dbd_mysql, "DBD::mysql loaded");

  my $dbh_1 = DBI->connect('dbi:mysql:test', undef, undef, { RaiseError => 0, PrintError => 0 });

 SKIP: {
    skip "Could not connect to test database: $DBI::errstr", 5 unless $dbh_1;
    ok(my $thread_1 = $dbh_1->{'mysql_thread_id'}, "Connected 1");

    my $dbh_2 = DBI->connect('dbi:mysql:test', undef, undef, { RaiseError => 0, PrintError => 0 });
    ok(my $thread_2 = $dbh_2->{'mysql_thread_id'}, "Connected 2");

    is($thread_1, $thread_2, "got the same connection both times");

    my $dbh_3 = DBI->connect('dbi:mysql:test', undef, undef, { RaiseError => 0, PrintError => 1 });
    ok(my $thread_3 = $dbh_3->{'mysql_thread_id'}, "Connected 3");

    isnt($thread_1, $thread_3, "got different connection from different attributes");


  }


} 

1;
