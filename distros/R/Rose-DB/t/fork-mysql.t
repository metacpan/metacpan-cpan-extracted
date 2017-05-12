#!/usr/bin/perl -w

use strict;

require Test::More;

if($^O =~ /MSWin/)
{
  Test::More->import(skip_all => "Can't fork() on Win32");
}
else
{
  Test::More->import(tests => 1);
}

use POSIX ':sys_wait_h';

use Rose::DB;

require 't/test-lib.pl';

no warnings 'once';
my $db_type = $Rose::DB::TEST::DB_TYPE || 'mysql_admin';

if(have_db($db_type))
{
  my $db = Rose::DB->new($db_type);

  eval
  {
    my $dbh = $db->dbh;
    local $dbh->{'PrintError'} = 0;
    $dbh->do('DROP TABLE fork_test');
  };

  $db->dbh->do('CREATE TABLE fork_test (i int)');
  $db->dbh->do('INSERT INTO fork_test (i) VALUES (1)');  
  $db->dbh->do('INSERT INTO fork_test (i) VALUES (2)');

  $SIG{'CHLD'} = \&Reaper;

  if(fork())
  {
    # Parent
    sleep(3);
    my $sth = $db->dbh->prepare('SELECT COUNT(*) FROM fork_test WHERE i > 2');
    $sth->execute;
    my $count = $sth->fetchrow_array;
    is($count, 1, 'fork test');
  }
  else
  {
    # Child
    $db->dbh->do('INSERT INTO fork_test (i) VALUES (3)');
    $db = undef;
    exit(0);
  }
}
else
{
  SKIP: { skip("$db_type not available", 1) }
}

sub Reaper 
{
  my $child;
  1 while(waitpid(-1, WNOHANG) > 0);
  $SIG{'CHLD'} = \&Reaper;
}
