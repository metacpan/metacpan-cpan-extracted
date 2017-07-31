use Test2::Bundle::Extended;
use Guard 'scope_guard';
use Path::Tiny 'path';
use Proc::tored::PidFile;

my $dir = Path::Tiny->tempdir('temp.XXXXXX', CLEANUP => 1, EXLOCK => 0);
skip_all 'could not create writable temp directory' unless -w $dir;

my $path = $dir->child("pidfile-$$");

ok my $pidfile = Proc::tored::PidFile->new(file_path => "$path"), 'new';

subtest 'initial values' => sub {
  scope_guard { $pidfile->clear_file };

  is $pidfile->read_file, 0, 'read_file: initial value is 0';
  is $pidfile->running_pid, 0, 'running_pid: initial value is 0';
  ok !$pidfile->is_running, 'is_running: initially false';
};

subtest 'positive path' => sub {
  scope_guard { $pidfile->clear_file };

  ok my $lock = $pidfile->lock, 'lock';
  is $pidfile->read_file, $$, 'read_file';
  is $pidfile->running_pid, $$, 'running_pid';
  ok $pidfile->is_running, 'is_running';
  ok !$pidfile->lock, '!lock';

  undef $lock;
  is $pidfile->read_file, 0, 'read_file: lock cleared';
  is $pidfile->running_pid, 0, 'running_pid: lock cleared';
  ok !$pidfile->is_running, 'is_running: lock cleared';

  $pidfile->file->spew("1234\n");
  is $pidfile->read_file, 1234, 'read_file: non-existent pid';
  is $pidfile->running_pid, 0, 'running_pid: non-existent pid';
  ok !$pidfile->is_running, 'is_running: non-existent pid';
};

subtest 'atomicity' => sub {
  scope_guard { $pidfile->clear_file };

  $pidfile->lockfile->file->touch;
  scope_guard { $pidfile->lockfile->file->remove };
  is $pidfile->write_file, 0, 'write_file returns 0 if write_lock fails';
};

done_testing;
