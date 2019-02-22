use Test::Most tests => 12;
use File::Signature;
use File::Spec;
use File::Copy;
use Storable;
use Spreadsheet::Read;
use Log::Log4perl::Shortcuts qw(:all);
use Spreadsheet::Read::Ingester;





#set_failure_handler ( \&test_cleanup );

diag( "Running Spreadsheet::Read::Ingester tests" );
my $configdir = File::UserConfig->new(dist => 'Spreadsheet-Read-Ingester')->configdir;

my $tmp_dir = File::Spec->catfile($configdir, 'tmp');
if (!-d $tmp_dir) {
  mkdir $tmp_dir or die 'Could not create temporary directory';
}

opendir (DIR, $configdir) or die 'Could not open directory.';
my @files = readdir (DIR) or die 'Could not read files from config directory';
closedir (DIR);

foreach my $file (@files) {
  my $source = File::Spec->catfile($configdir, $file);
  next if !-f $source;
  copy $source, File::Spec->catfile($tmp_dir, $file)
    or die 'Could not copy file to tmp directory';
}

my $sig = File::Signature->new('t/test_files/test.csv')->{digest};
$sig .= '-clip1strip1';
my $new_file = File::Spec->catfile($configdir, $sig);

# make sure file doesn't exist from any previous failed test
unlink $new_file if -f $new_file;

my $data;
lives_ok {
  $data = Spreadsheet::Read::Ingester->new( 't/test_files/test.csv', strip => 1, clip => 1 );
} 'Can create new object';

like ($data->parses("CSV"), qr/CSV/, 'can get parser type');

my @rows = $data->rows(1);
is ($rows[1][1], 'four', 'returns rows');

my $new_data = Spreadsheet::Read::Ingester->new('t/test_files/test2.csv');

lives_ok {
  $data->add('t/test_files/test2.csv');
} 'Can add data to existing data';

is (scalar keys %{$data->[0]{sheet}}, 2, 'has two sheets');



is (-f $new_file, 1, 'created parsed file');

my $dummy_data = { hash => 1 };

store $dummy_data, $new_file;

lives_ok {
  $data = Spreadsheet::Read::Ingester->new('t/test_files/test.csv', strip => 1, clip => 1 );
} 'attempts to get parsed data';


is ($data->{hash}, 1, 'retrieves parsed data');
sleep 2;

lives_ok {
  Spreadsheet::Read::Ingester->cleanup();
} 'cleans up directory';

warnings_like {
  Spreadsheet::Read::Ingester->cleanup('blah');
} qr/accepts only/, 'warns when non-integer passed to cleanup method';

is (-e $new_file, 1, 'parsed file is not deleted');

Spreadsheet::Read::Ingester->cleanup(0);

is (-e $new_file, undef, 'parsed file is deleted');

# cleanup
unlink $new_file;

# restore files from tmp directory
foreach my $file (@files) {
  my $source = File::Spec->catfile($tmp_dir, $file);
  next if !-f $source;
  rename $source, File::Spec->catfile($configdir, $file) or die 'Could not rename file.';
}
rmdir $tmp_dir or die 'Could not remove tmp directory';
