use strict;
use warnings;
use Test::More 0.88;

# Archive::Any::Create 0.02 uses this
my $extractor = 'Archive::Tar';
eval "require $extractor"
  or plan skip_all => "$extractor required for this test";

use Cwd ();
use Encode qw( decode_utf8 encode_utf8 );
use Module::Faker::Dist;
use File::Temp ();
use Path::Class 0.06 qw( file );

my $MFD = 'Module::Faker::Dist';

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

my $dist = $MFD->from_file(file(qw(eg Append-UTF8.json))->stringify);

isa_ok($dist, $MFD);

my $archive = $dist->make_archive({ dir => $tmpdir });

{
  my $old_pwd = Cwd::getcwd();
  chdir $tmpdir or die "Failed to chdir to $tmpdir: $!";
  $extractor->extract_archive($archive)
    or die $extractor->error;
  chdir $old_pwd;
}

(my $dir = $archive) =~ s/\.(zip|tar\.(gz|bz2))$//;
my $file = file($dir, 'Changes');

ok( -e "$file", "file extracted" );

# on 5.14+ this will fail unless the file was passed through
# encode_utf8 before passing to Archive::Tar

like(
  # decode the slurped octects b/c we expect the file to be utf8
  decode_utf8(scalar $file->slurp),
  qr/codename 'M\x{fc}nchen'/,
  'file preserves utf8'
);

done_testing;
