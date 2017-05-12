use strict;
use warnings;
use Test::More tests => 11;
use File::Slurp;
use Path::Class::Dir;

# dev only
my $generate_xml = $ENV{GEN_XML} || 0;

# test ver2 to ver3 conversion
use_ok('SWISH::Prog::Config');

my $ver2_dir = Path::Class::Dir->new('t/config2');
my $ver3_dir = Path::Class::Dir->new('t/config3');

if (@ARGV) {

    # dev only
    for my $file (@ARGV) {
        diag("converting $file");
        my $xml = SWISH::Prog::Config->ver2_to_ver3( "$file", 1 );
        diag($xml);
    }
}
else {

    while ( my $file = $ver2_dir->next ) {
        next if -d $file;

        #diag("converting $file");
        my $xml = SWISH::Prog::Config->ver2_to_ver3( "$file", 1 );

        #diag($xml);

        my $filename  = $file->basename;
        my $ver3_file = $ver3_dir->file( $filename . ".xml" );

        if ($generate_xml) {
            write_file( "$ver3_file", $xml );
        }
        else {
            my $ver3 = read_file("$ver3_file");
            is( $xml, $ver3, "$file to xml" );
        }

    }

}
