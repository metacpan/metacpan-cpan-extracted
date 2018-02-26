use 5.006;

use Test::More;
use FindBin::libs;
use File::Basename   qw( basename );

delete $ENV{ COMPATIBLE_VERSION };

my $madness     = 'Module::FromPerlVer';

my @methodz
= qw
(
    perl_version
    version_dir
    source_dir
    source_files
    cleanup
    copy_source_dir
);

require_ok $madness
or BAIL_OUT "Failed require: '$madness'";

ok ! $madness->can( $_ ), "No pre-existing '$_'"
for @methodz;

eval { $madness->import; 1 }
? pass "Import executes."
: BAIL_OUT "Import fails: $@"
;

ok $madness->can( $_ ), "Import installs: '$_'"
for @methodz;

my ( $filz, $dirz ) = $madness->source_files;

ok -e $_, "File: '$_' after copy" 
for @$filz;

ok -d $_, "Directory: '$_' after copy."
for @$dirz;

$madness->cleanup;

ok ! -e $_, "Removed: '$_'" for @$filz;

done_testing;

__END__
