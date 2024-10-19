use Test2::V0;
use Storage::Abstract;
use File::Temp qw(tempdir);
use File::Spec;

use lib 't/lib';
use Storage::Abstract::Test;

################################################################################
# This tests the directory driver
################################################################################

my $dir = tempdir();
my $storage = Storage::Abstract->new(
	driver => 'directory',
	directory => $dir,
);

$storage->store('/some/file', get_testfile_handle);
ok $storage->is_stored('/some/file'), 'stored file 1 ok';

$storage->store('/some/other/file', get_testfile);
ok $storage->is_stored('/some/file'), 'stored file 2 ok';

my $fh2 = $storage->retrieve('/some/other/file', \my %info);

is slurp_handle($fh2), slurp_handle(get_testfile_handle), 'content ok';
is $info{mtime}, within(time, 3), 'mtime ok';
is $info{size}, get_testfile_size, 'size ok';

is $storage->list, bag {
	item 'some/file';
	item 'some/other/file';

	end();
},
	'file list ok';

$storage->dispose('/some/file');
ok !$storage->is_stored('/some/file'), 'foo disposed ok';

subtest 'should create a directory' => sub {
	my $new_dir = File::Spec->catdir($dir, 'nonexistent');

	like dies {
		Storage::Abstract->new(
			driver => 'directory',
			directory => $new_dir,
		);
	}, qr{does not exist};

	ok lives {
		Storage::Abstract->new(
			driver => 'directory',
			directory => $new_dir,
			create_directory => 1,
		);
	}, 'created driver ok';

	ok -d $new_dir, 'directory created ok';
};

done_testing;

