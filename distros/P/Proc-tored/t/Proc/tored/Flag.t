use Test2::Bundle::Extended -target => 'Proc::tored::Flag';
use Path::Tiny 'path';

my $dir = Path::Tiny->tempdir('temp.XXXXXX', CLEANUP => 1, EXLOCK => 0);
skip_all 'could not create writable temp directory' unless -w $dir;
my $path = $dir->child('flag');

ok my $flag = $CLASS->new(touch_file_path => "$path"), 'new';
ok !$flag->is_set, '!is_set';
ok !$flag->file->exists, '!file->exists';

ok $flag->set, 'set';
ok $flag->is_set, 'is_set';
ok $flag->file->exists, 'file->exists';

ok $flag->unset, 'unset';
ok !$flag->is_set, '!is_set';
ok !$flag->file->exists, '!file->exists';

done_testing;
