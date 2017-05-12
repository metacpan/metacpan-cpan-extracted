use NL::File::Lock;
use Test::Simple qw(no_plan);

my $tmp_filename = 'tmp_file.txt';
my $tmp_lock_filename = $tmp_filename.'.lck';

ok(&NL::File::Lock::lock_write($tmp_filename, { 'timeout' => 2, 'time_sleep' => 0.1 }), 'Locked EX (for writing)');
ok(&NL::File::Lock::unlock_not_unlink($tmp_filename), 'Unlocking file, but not removing lockfile');
ok(-f $tmp_lock_filename, 'Checking that lockfile exists');
ok(&NL::File::Lock::lock_read($tmp_filename, { 'timeout' => 2, 'time_sleep' => 0.1 }), 'Locked SH (for reading)');
ok(&NL::File::Lock::unlock($tmp_filename), 'Unlocking file, and removing lockfile');
ok(!-f $tmp_lock_filename, 'Checking that lockfile does not exists');




