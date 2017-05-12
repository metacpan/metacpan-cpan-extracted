#!/usr/bin/perl -w

use strict;

require Test::More;

eval { require Storable };

if($@)
{
  Test::More->import(skip_all => 'Could not load Storable');
}
else
{
  Test::More->import(tests => 1 + (4 * 5));
}

use Config;
use FindBin qw($Bin);

require 't/test-lib.pl';
use_ok('Rose::DB');

my $frozen_file = "$Bin/frozen";

my $Perl = $^X;

if($^O ne 'VMS')
{
  $Perl .= $Config{'_exe'}  unless($Perl =~ /$Config{'_exe'}$/i);
}

my($db, @Cleanup);

foreach my $db_type (qw(pg mysql informix sqlite oracle))
{
  $db = get_db($db_type);

  unless($db)
  {
    SKIP: { skip("Could not connect to $db_type", 4) }
    next;
  }

  CLEAR:
  {
    my $dbh = $db->dbh;
    local $dbh->{'RaiseError'} = 0;
    local $dbh->{'PrintError'} = 0;
    $dbh->do('DROP TABLE rose_db_storable_test');  
  }

  $db->dbh->do('CREATE TABLE rose_db_storable_test (i INT)');  

  CLEANUP:
  {
    my $dbh = $db->dbh;
    push(@Cleanup, sub { $dbh->do('DROP TABLE rose_db_storable_test') });
  }

  my $frozen = Storable::freeze($db);

  Storable::nstore($db, $frozen_file);

  my $thawed = Storable::thaw($frozen);

  ok(!defined $thawed->{'dbh'}, "check dbh - $db_type");

  if(!defined $db->password)
  {
    ok(!defined $thawed->{'password'}, "check password - $db_type");
    ok(!defined $thawed->{'password_closure'}, "check password closure - $db_type");
  }
  else
  {
    ok(!defined $thawed->{'password'}, "check password - $db_type");
    ok(ref $thawed->{'password_closure'}, "check password closure - $db_type");
  }

  $thawed->dbh->do('DROP TABLE rose_db_storable_test');
  pop(@Cleanup);

  # Disconnect to flush SQLite memory buffers
  if($db_type eq 'sqlite')
  {
    $thawed->disconnect;
    $db->disconnect;
  }

  $db->dbh->do('CREATE TABLE rose_db_storable_test (i INT)');  

  CLEANUP:
  {
    my $dbh = $db->dbh;
    push(@Cleanup, sub 
    {
      $dbh->{'RaiseError'} = 0;
      $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_storable_test');
    });
  }

  my($ok, $script_fh);

  # Perl 5.8.x and later support the FILEHANDLE,MODE,EXPR,LIST form of 
  # open, but not (apparently) on Windows
  if($Config{'version'} =~ /^5\.([89]|10)\./ && $^O !~ /Win32/i)
  {
    $ok = open($script_fh, '-|', $Perl, 't/storable.ext', $db_type);
  }
  else
  {
    $ok = open($script_fh, "$Perl t/storable.ext $db_type |");
  }

  if($ok)
  {
    chomp(my $line = <$script_fh>);
    close($script_fh);
    is($line, 'dropped', "external test - $db_type");
    pop(@Cleanup)  if($line eq 'dropped');
  }
  else
  {
    ok(0, "Failed to open external script for $db_type - $!");
  }
}

END
{
  unlink($frozen_file); # ignore errors

  foreach my $code (@Cleanup)
  {
    $code->();
  }
}
