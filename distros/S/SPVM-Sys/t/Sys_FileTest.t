use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use Cwd 'getcwd';

use SPVM 'TestCase::Sys::FileTest';
use SPVM 'Sys::FileTest';
use SPVM 'Sys';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

my $file_not_exists = "t/ftest/not_exists.txt";
my $file_empty = "t/ftest/file_empty.txt";
my $file_bytes8 = "t/ftest/file_bytes8.txt";
my $file_myexe_exe = "t/ftest/myexe.exe";
my $file_myexe_bat = "t/ftest/myexe.bat";
my $file_myexe_cmd = "t/ftest/myexe.cmd";

# File tests
{
  ok(SPVM::TestCase::Sys::FileTest->A);
  is(sprintf("%.14g", SPVM::Sys::FileTest->A($file_empty)), sprintf("%.14g", -A $file_empty));
}
{
  ok(SPVM::TestCase::Sys::FileTest->C);
  is(sprintf("%.14g", SPVM::Sys::FileTest->C($file_empty)), sprintf("%.14g", -C $file_empty));
}
{
  ok(SPVM::TestCase::Sys::FileTest->M);
  is(sprintf("%.14g", SPVM::Sys::FileTest->M($file_empty)), sprintf("%.14g", -M $file_empty));
}
{
  ok(SPVM::TestCase::Sys::FileTest->O);
  is(!!SPVM::Sys::FileTest->O($file_not_exists), !!-O $file_not_exists);
  is(!!SPVM::Sys::FileTest->O($file_empty), !!-O $file_empty);
  is(!!SPVM::Sys::FileTest->O($file_bytes8), !!-O $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->R);
  is(!!SPVM::Sys::FileTest->R($file_not_exists), !!-R $file_not_exists);
  is(!!SPVM::Sys::FileTest->R($file_empty), !!-R $file_empty);
  is(!!SPVM::Sys::FileTest->R($file_bytes8), !!-R $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->S);
  is(!!SPVM::Sys::FileTest->S($file_empty), !!-S $file_empty);
  is(!!SPVM::Sys::FileTest->S($file_bytes8), !!-S $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->W);
  is(!!SPVM::Sys::FileTest->W($file_not_exists), !!-W $file_not_exists);
  is(!!SPVM::Sys::FileTest->W($file_empty), !!-W $file_empty);
  is(!!SPVM::Sys::FileTest->W($file_bytes8), !!-W $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->X);
  is(!!SPVM::Sys::FileTest->X($file_not_exists), !!-X $file_not_exists);
  is(!!SPVM::Sys::FileTest->X($file_empty), !!-X $file_empty);
  ok(SPVM::Sys::FileTest->X($file_myexe_exe));
  ok(SPVM::Sys::FileTest->X($file_myexe_bat));
  ok(SPVM::Sys::FileTest->X($file_myexe_cmd));
  is(!!SPVM::Sys::FileTest->X($file_myexe_exe), !!-X $file_myexe_exe);
  is(!!SPVM::Sys::FileTest->X($file_myexe_bat), !!-X $file_myexe_bat);
  is(!!SPVM::Sys::FileTest->X($file_myexe_cmd), !!-X $file_myexe_cmd);
}
{
  ok(SPVM::TestCase::Sys::FileTest->d);
  is(!!SPVM::Sys::FileTest->d($file_not_exists), !!-d $file_not_exists);
  is(!!SPVM::Sys::FileTest->d($file_empty), !!-d $file_empty);
  is(!!SPVM::Sys::FileTest->d($file_bytes8), !!-d $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->f);
  is(!!SPVM::Sys::FileTest->f($file_not_exists), !!-f $file_not_exists);
  is(!!SPVM::Sys::FileTest->f($file_empty), !!-f $file_empty);
  is(!!SPVM::Sys::FileTest->f($file_bytes8), !!-f $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->g);
  is(!!SPVM::Sys::FileTest->g($file_not_exists), !!-g $file_not_exists);
  is(!!SPVM::Sys::FileTest->g($file_empty), !!-g $file_empty);
  is(!!SPVM::Sys::FileTest->g($file_bytes8), !!-g $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->k);
  is(!!SPVM::Sys::FileTest->k($file_not_exists), !!-k $file_not_exists);
  is(!!SPVM::Sys::FileTest->k($file_empty), !!-k $file_empty);
  is(!!SPVM::Sys::FileTest->k($file_bytes8), !!-k $file_bytes8);
}
if (SPVM::Sys->defined("_WIN32")) {
  warn "[Test Output]The tests of lstat is skiped.";
}
else {
  ok(SPVM::TestCase::Sys::FileTest->l);
  is(!!SPVM::Sys::FileTest->l($file_not_exists), !!-l $file_not_exists);
  is(!!SPVM::Sys::FileTest->l($file_empty), !!-l $file_empty);
  is(!!SPVM::Sys::FileTest->l($file_bytes8), !!-l $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->b);
  is(!!SPVM::Sys::FileTest->b($file_not_exists), !!-b $file_not_exists);
  is(!!SPVM::Sys::FileTest->b($file_empty), !!-b $file_empty);
  is(!!SPVM::Sys::FileTest->b($file_bytes8), !!-b $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->o);
  is(!!SPVM::Sys::FileTest->o($file_not_exists), !!-o $file_not_exists);
  is(!!SPVM::Sys::FileTest->o($file_empty), !!-o $file_empty);
  is(!!SPVM::Sys::FileTest->o($file_bytes8), !!-o $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->p);
  is(!!SPVM::Sys::FileTest->p($file_not_exists), !!-p $file_not_exists);
  is(!!SPVM::Sys::FileTest->p($file_empty), !!-p $file_empty);
  is(!!SPVM::Sys::FileTest->p($file_bytes8), !!-p $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->r);
  is(!!SPVM::Sys::FileTest->r($file_not_exists), !!-r $file_not_exists);
  is(!!SPVM::Sys::FileTest->r($file_empty), !!-r $file_empty);
  is(!!SPVM::Sys::FileTest->r($file_bytes8), !!-r $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->s);
  is(!!SPVM::Sys::FileTest->s($file_empty), !!-s $file_empty);
  is(!!SPVM::Sys::FileTest->s($file_bytes8), !!-s $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->u);
  is(!!SPVM::Sys::FileTest->u($file_not_exists), !!-u $file_not_exists);
  is(!!SPVM::Sys::FileTest->u($file_empty), !!-u $file_empty);
  is(!!SPVM::Sys::FileTest->u($file_bytes8), !!-u $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->z);
  is(!!SPVM::Sys::FileTest->z($file_empty), !!-z $file_empty);
  is(!!SPVM::Sys::FileTest->z($file_bytes8), !!-z $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->w);
  is(!!SPVM::Sys::FileTest->w($file_not_exists), !!-w $file_not_exists);
  is(!!SPVM::Sys::FileTest->w($file_empty), !!-w $file_empty);
  is(!!SPVM::Sys::FileTest->w($file_bytes8), !!-w $file_bytes8);
}
{
  ok(SPVM::TestCase::Sys::FileTest->x);
  is(!!SPVM::Sys::FileTest->x($file_not_exists), !!-x $file_not_exists);
  is(!!SPVM::Sys::FileTest->x($file_empty), !!-x $file_empty);
  ok(SPVM::Sys::FileTest->x($file_myexe_exe));
  ok(SPVM::Sys::FileTest->x($file_myexe_bat));
  ok(SPVM::Sys::FileTest->x($file_myexe_cmd));
  is(!!SPVM::Sys::FileTest->x($file_myexe_exe), !!-x $file_myexe_exe);
  is(!!SPVM::Sys::FileTest->x($file_myexe_bat), !!-x $file_myexe_bat);
  is(!!SPVM::Sys::FileTest->x($file_myexe_cmd), !!-x $file_myexe_cmd);
}

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
