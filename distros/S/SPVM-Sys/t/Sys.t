use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'Sys';
use SPVM 'Int';
use SPVM 'Long';
use SPVM 'Double';

use SPVM 'TestCase::Sys';
use SPVM 'Sys::OS';
use File::stat ();

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# osname
{
  is(SPVM::Sys->osname, $^O);
}

# env
{
  is(SPVM::Sys->env("PATH"), $ENV{PATH});
}

# time
{
  is(SPVM::Sys->time, time);
}

# localtime
{
  my $time = time;
  
  #     0    1    2     3     4    5     6     7     8
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
  
  my $tm = SPVM::Sys->localtime($time);
  
  is($tm->tm_sec, $sec);
  is($tm->tm_min, $min);
  is($tm->tm_hour, $hour);
  is($tm->tm_mday, $mday);
  is($tm->tm_mon, $mon);
  is($tm->tm_year, $year);
  is($tm->tm_wday, $wday);
  is($tm->tm_yday, $yday);
  is($tm->tm_isdst, $isdst);
}

# gmtime
{
  my $time = time;
  
  #     0    1    2     3     4    5     6     7     8
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);
  
  my $tm = SPVM::Sys->gmtime($time);
  
  is($tm->tm_sec, $sec);
  is($tm->tm_min, $min);
  is($tm->tm_hour, $hour);
  is($tm->tm_mday, $mday);
  is($tm->tm_mon, $mon);
  is($tm->tm_year, $year);
  is($tm->tm_wday, $wday);
  is($tm->tm_yday, $yday);
  is($tm->tm_isdst, $isdst);
}

# process_id
{
  is(SPVM::Sys->process_id, $$);
}

# stat
{
  my $test_dir = "$FindBin::Bin";
  {
    my $file = "$test_dir/ftest/readline_long_lines.txt";
    my $stat = SPVM::Sys->stat($file);
    my $stat_expected = File::stat::stat($file);
    
    is($stat->st_dev, $stat_expected->dev, "st_dev");
    is($stat->st_ino, $stat_expected->ino, "st_ino");
    is($stat->st_mode, $stat_expected->mode, "st_mode");
    if ($stat->st_nlink == $stat_expected->nlink) {
      is($stat->st_nlink, $stat_expected->nlink, "st_nlink");
    }
    else {
      warn "[Test Output]Got: " . $stat->st_nlink . ", Expected: " . $stat_expected->nlink;
    }
    is($stat->st_uid, $stat_expected->uid, "uid");
    is($stat->st_gid, $stat_expected->gid, "gid");
    is($stat->st_rdev, $stat_expected->rdev, "rdev");
    is($stat->st_size, $stat_expected->size, "size");
    is($stat->st_atime, $stat_expected->atime, "atime");
    is($stat->st_mtime, $stat_expected->mtime, "mtime");
    is($stat->st_ctime, $stat_expected->ctime, "ctime");
    
    unless ($^O eq 'MSWin32') {
      is($stat->st_blksize, $stat_expected->blksize, "blksize");
      is($stat->st_blocks, $stat_expected->blocks, "blocks");
    }
  }
}

{
  my $file_not_exists = "t/ftest/not_exists.txt";
  my $file_empty = "t/ftest/file_empty.txt";
  my $file_bytes8 = "t/ftest/file_bytes8.txt";
  my $file_myexe_exe = "t/ftest/myexe.exe";
  my $file_myexe_bat = "t/ftest/myexe.bat";
  my $file_myexe_cmd = "t/ftest/myexe.cmd";

  # File tests
  {
    ok(SPVM::TestCase::Sys->A);
    is(sprintf("%.14g", SPVM::Sys->A($file_empty)), sprintf("%.14g", -A $file_empty));
  }
  {
    ok(SPVM::TestCase::Sys->C);
    is(sprintf("%.14g", SPVM::Sys->C($file_empty)), sprintf("%.14g", -C $file_empty));
  }
  {
    ok(SPVM::TestCase::Sys->M);
    is(sprintf("%.14g", SPVM::Sys->M($file_empty)), sprintf("%.14g", -M $file_empty));
  }
  {
    ok(SPVM::TestCase::Sys->O);
    is(!!SPVM::Sys->O($file_not_exists), !!-O $file_not_exists);
    is(!!SPVM::Sys->O($file_empty), !!-O $file_empty);
    is(!!SPVM::Sys->O($file_bytes8), !!-O $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->R);
    is(!!SPVM::Sys->R($file_not_exists), !!-R $file_not_exists);
    is(!!SPVM::Sys->R($file_empty), !!-R $file_empty);
    is(!!SPVM::Sys->R($file_bytes8), !!-R $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->S);
    is(!!SPVM::Sys->S($file_empty), !!-S $file_empty);
    is(!!SPVM::Sys->S($file_bytes8), !!-S $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->W);
    is(!!SPVM::Sys->W($file_not_exists), !!-W $file_not_exists);
    is(!!SPVM::Sys->W($file_empty), !!-W $file_empty);
    is(!!SPVM::Sys->W($file_bytes8), !!-W $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->X);
    is(!!SPVM::Sys->X($file_not_exists), !!-X $file_not_exists);
    is(!!SPVM::Sys->X($file_empty), !!-X $file_empty);
    ok(SPVM::Sys->X($file_myexe_exe));
    ok(SPVM::Sys->X($file_myexe_bat));
    ok(SPVM::Sys->X($file_myexe_cmd));
    is(!!SPVM::Sys->X($file_myexe_exe), !!-X $file_myexe_exe);
    is(!!SPVM::Sys->X($file_myexe_bat), !!-X $file_myexe_bat);
    is(!!SPVM::Sys->X($file_myexe_cmd), !!-X $file_myexe_cmd);
  }
  {
    ok(SPVM::TestCase::Sys->d);
    is(!!SPVM::Sys->d($file_not_exists), !!-d $file_not_exists);
    is(!!SPVM::Sys->d($file_empty), !!-d $file_empty);
    is(!!SPVM::Sys->d($file_bytes8), !!-d $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->f);
    is(!!SPVM::Sys->f($file_not_exists), !!-f $file_not_exists);
    is(!!SPVM::Sys->f($file_empty), !!-f $file_empty);
    is(!!SPVM::Sys->f($file_bytes8), !!-f $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->g);
    is(!!SPVM::Sys->g($file_not_exists), !!-g $file_not_exists);
    is(!!SPVM::Sys->g($file_empty), !!-g $file_empty);
    is(!!SPVM::Sys->g($file_bytes8), !!-g $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->k);
    is(!!SPVM::Sys->k($file_not_exists), !!-k $file_not_exists);
    is(!!SPVM::Sys->k($file_empty), !!-k $file_empty);
    is(!!SPVM::Sys->k($file_bytes8), !!-k $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->b);
    is(!!SPVM::Sys->b($file_not_exists), !!-b $file_not_exists);
    is(!!SPVM::Sys->b($file_empty), !!-b $file_empty);
    is(!!SPVM::Sys->b($file_bytes8), !!-b $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->o);
    is(!!SPVM::Sys->o($file_not_exists), !!-o $file_not_exists);
    is(!!SPVM::Sys->o($file_empty), !!-o $file_empty);
    is(!!SPVM::Sys->o($file_bytes8), !!-o $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->p);
    is(!!SPVM::Sys->p($file_not_exists), !!-p $file_not_exists);
    is(!!SPVM::Sys->p($file_empty), !!-p $file_empty);
    is(!!SPVM::Sys->p($file_bytes8), !!-p $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->r);
    is(!!SPVM::Sys->r($file_not_exists), !!-r $file_not_exists);
    is(!!SPVM::Sys->r($file_empty), !!-r $file_empty);
    is(!!SPVM::Sys->r($file_bytes8), !!-r $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->s);
    is(!!SPVM::Sys->s($file_empty), !!-s $file_empty);
    is(!!SPVM::Sys->s($file_bytes8), !!-s $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->u);
    is(!!SPVM::Sys->u($file_not_exists), !!-u $file_not_exists);
    is(!!SPVM::Sys->u($file_empty), !!-u $file_empty);
    is(!!SPVM::Sys->u($file_bytes8), !!-u $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->z);
    is(!!SPVM::Sys->z($file_empty), !!-z $file_empty);
    is(!!SPVM::Sys->z($file_bytes8), !!-z $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->w);
    is(!!SPVM::Sys->w($file_not_exists), !!-w $file_not_exists);
    is(!!SPVM::Sys->w($file_empty), !!-w $file_empty);
    is(!!SPVM::Sys->w($file_bytes8), !!-w $file_bytes8);
  }
  {
    ok(SPVM::TestCase::Sys->x);
    is(!!SPVM::Sys->x($file_not_exists), !!-x $file_not_exists);
    is(!!SPVM::Sys->x($file_empty), !!-x $file_empty);
    ok(SPVM::Sys->x($file_myexe_exe));
    ok(SPVM::Sys->x($file_myexe_bat));
    ok(SPVM::Sys->x($file_myexe_cmd));
    is(!!SPVM::Sys->x($file_myexe_exe), !!-x $file_myexe_exe);
    is(!!SPVM::Sys->x($file_myexe_bat), !!-x $file_myexe_bat);
    is(!!SPVM::Sys->x($file_myexe_cmd), !!-x $file_myexe_cmd);
  }
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys->mkdir("$tmp_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys->umask("$tmp_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys->rmdir("$tmp_dir"));
}

{
  my $test_dir = "$FindBin::Bin";
  ok(SPVM::TestCase::Sys->chdir("$test_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys->chmod("$tmp_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys->unlink("$tmp_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys->rename("$tmp_dir"));
}

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
