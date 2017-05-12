use strict;
use warnings;
use Test::More tests => 14;
use Digest::MD5;
use Config;
use File::Spec;
use Cwd;
use Capture::Tiny 0.36 'capture';

require_ok('Siebel::Srvrmgr::Exporter');

# calculated with:
# -for Linux
# perl -MDigest::MD5 -e '$filename = shift; open($fh, "<", $filename) or die $!; binmode($fh); print Digest::MD5->new->addfile($fh)->hexdigest, "\n"' test.txt
# - for Windows
#
my $expected_digest;

# the differences below are due the line end character differences
if ( $Config{osname} eq 'MSWin32' ) {

    $expected_digest = 'cafb36f3bf6c2387bc4b9ffab3337ea8';

}
else {    # else is for UNIX-line OS

    $expected_digest = 'a64debe4934a962da1310048637e3a9e';

}

my $filename = 'test.txt';

# srvrmgr-mock.pl ignores all parameters

my $dummy = 'foobar';
my $mock = File::Spec->catfile( $Config{sitebin}, 'srvrmgr-mock.pl' );
note("Attempting $mock");
unless ( -e $mock ) {
    diag(
"Could not locate srvrmgr-mock.pl in Config sitebin ($Config{sitebin}). Hoping that the script is available on the current PATH"
    );

    my @paths = split( ':', $ENV{PATH} );

    foreach my $path (@paths) {
        my $full_path = File::Spec->catfile( $path, 'srvrmgr-mock.pl' );

        if ( -e $full_path ) {
            $mock = $full_path;
            last;
        }
    }
    diag("Found srvrmgr-mock.pl ('$mock')");
}
ok( -e $mock, 'srvrmgr-mock.pl is available' );
note('Fetching values, this can take some seconds');
my $exports = File::Spec->catfile( 'blib', 'script', 'export_comps.pl' );
ok( -e $exports, 'export_comps.pl exists' );
ok( -r $exports, 'export_comps.pl is readable' );
my $path_to_perl = $Config{perlpath};
my $repeat = 5;
diag("Repeating tests $repeat times with '$path_to_perl', '$exports', '$mock'");

for ( 1 .. $repeat ) {
    my ( $stdout, $stderr, $exit ) = capture {
        system( $path_to_perl, '-Ilib', $exports, '-s', $dummy,
            '-g',   $dummy,   '-e',   $dummy, '-u',
            $dummy, '-p',     $dummy, '-b',   $mock,
            '-r',   'SRProc', '-x',   '-o',   $filename,
            '-q'
        );
    };

    is( $exit, 0, "successfully executed $exports" )
      or diag("Failed to execute $exports: $stderr");

    unless ( $exit == 0 ) {
        BAIL_OUT("$exports failed due previous error");
    }

    open( my $fh, '<', $filename ) or diag("Can't open '$filename': $!");
    binmode($fh);
    is( Digest::MD5->new->addfile($fh)->hexdigest(),
        $expected_digest, 'got expected output from srvrmgr-mock' );
    close($fh);
    unlink($filename) or diag("Cannot remove $filename: $!");
}

