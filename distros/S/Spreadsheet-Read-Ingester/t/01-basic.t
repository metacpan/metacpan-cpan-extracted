use Test::Most;
use Test::Output;
use File::Spec;
use Storable;
BEGIN {
  use Test::File::ShareDir::Module { "Spreadsheet::Read::Ingester" => "share/" };
  use Test::File::ShareDir::Dist { "Spreadsheet-Read-Ingester" => "share/" };
}
use Spreadsheet::Read::Ingester;







my $tests = 7; # keep on line 17 for ,i (increment and ,d (decrement)
plan tests => $tests;
diag( "Running Spreadsheet::Read::Ingester tests" );
my $configdir = File::UserConfig->new(dist => 'Spreadsheet-Read-Ingester')->configdir;

opendir (DIR, $configdir);
my @files = readdir (DIR);
closedir (DIR);

my $file_count = scalar @files;
my %files = map { $_ => 1 } @files;

my $data;
lives_ok {
  $data = Spreadsheet::Read::Ingester->new( 't/test_files/test.csv' );
} 'Can create new object';

opendir (DIR, $configdir);
my @new_files = readdir (DIR);
closedir (DIR);

is (scalar @new_files, $file_count + 1, 'created parsed file');

# get the name of the new file
my $file;
foreach my $f (@new_files) {
  if (!$files{$f}) {
    $file = $f;
    last;
  }
}

$file = File::Spec->catfile($configdir, $file);
my $dummy_data = { hash => 1 };

store $dummy_data, $file;

lives_ok {
  $data = Spreadsheet::Read::Ingester->new('t/test_files/test.csv' );
} 'attempts to get parsed data';

is ($data->{hash}, 1, 'retrieves parsed data');

lives_ok {
  Spreadsheet::Read::Ingester->cleanup();
} 'cleans up directory';

is (-e $file, 1, 'parsed file is not deleted');

Spreadsheet::Read::Ingester->cleanup(0);

is (-e $file, undef, 'parsed file is deleted');

# cleanup dir
opendir (DIR, $configdir) or die 'Could not open directory.';
@files = readdir (DIR);
closedir (DIR);
foreach my $file (@files) {
  $file = File::Spec->catfile($configdir, $file);
  unlink $file if -f $file;
}
