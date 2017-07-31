use Test2::Bundle::Extended;
use Guard 'scope_guard';
use Path::Tiny 'path';
use Proc::tored::LockFile;

my $dir = Path::Tiny->tempdir('temp.XXXXXX', CLEANUP => 1, EXLOCK => 0);
skip_all 'could not create writable temp directory' unless -w $dir;

my $path = $dir->child("lockfile-$$");

ok my $lockfile = Proc::tored::LockFile->new(file_path => "$path"), 'new';
ok !$lockfile->exists, '!exists';
ok my $lock = $lockfile->lock, 'lock';
ok $lockfile->exists, 'exists';
ok !$lockfile->lock, '!lock';
undef $lock;
ok !$lockfile->exists, '!exists';
ok $lockfile->lock, 'lock';

done_testing;
