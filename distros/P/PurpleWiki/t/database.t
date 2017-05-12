# database.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 5 };

use PurpleWiki::Database;
use PurpleWiki::Config;

my $configdir = 't';
my $file = "t/$$";
my $dir = "t/testdir$$";
my $content = "sample content";
my $tempdir = 't/temp';
my $lockdir = "$tempdir/lockmain";


# filehandling
ok(PurpleWiki::Database::WriteStringToFile($file, $content), 1);
ok(PurpleWiki::Database::ReadFile($file), $content);
ok(PurpleWiki::Database::CreateDir($dir) && -d $dir);

# lockhandling
my $config = new PurpleWiki::Config($configdir);
ok(PurpleWiki::Database::RequestLock($config) && -d $lockdir);
ok(PurpleWiki::Database::ReleaseLock($config) && ! -d $lockdir);

# diff handling elsewhere, in the page tests
   
sub END { 
    unlink($file);
    rmdir($dir);
    rmdir($tempdir);
}
