use Test::Most tests => 8;
use File::Signature;
use File::Spec;
use Storable;
use Spreadsheet::Read::Ingester;







diag( "Running Spreadsheet::Read::Ingester tests" );
my $configdir = File::UserConfig->new(dist => 'Spreadsheet-Read-Ingester')->configdir;

my $sig = File::Signature->new('t/test_files/test.csv')->{digest};
my $new_file = File::Spec->catfile($configdir, $sig);

# make sure file doesn't exist from a previous failed test
unlink $new_file if -f $new_file;

my $data;
lives_ok {
  $data = Spreadsheet::Read::Ingester->new( 't/test_files/test.csv' );
} 'Can create new object';

is (1, -f $new_file, 'created parsed file');

my $dummy_data = { hash => 1 };

store $dummy_data, $new_file;

lives_ok {
  $data = Spreadsheet::Read::Ingester->new('t/test_files/test.csv' );
} 'attempts to get parsed data';

is ($data->{hash}, 1, 'retrieves parsed data');

lives_ok {
  Spreadsheet::Read::Ingester->cleanup();
} 'cleans up directory';

warnings_like {
  Spreadsheet::Read::Ingester->cleanup('blah');
} qr/accepts only/, 'warns when non-integer passed to cleanup method';

is (-e $new_file, 1, 'parsed file is not deleted');

Spreadsheet::Read::Ingester->cleanup(0);

is (-e $new_file, undef, 'parsed file is deleted');

unlink $new_file if -f $new_file;
