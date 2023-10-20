#!perl
# This test file has been automatically generated. Any change made here will be lost.
# Edit the script in ./build/build_modules.pl instead
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use Module::Generic;
    use Scalar::Util ();
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Net::API::CPAN::DownloadUrl' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::DownloadUrl->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::DownloadUrl' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::DownloadUrl->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/DownloadUrl.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'checksum_md5' );
can_ok( $obj, 'checksum_sha256' );
can_ok( $obj, 'date' );
can_ok( $obj, 'download_url' );
can_ok( $obj, 'object' );
can_ok( $obj, 'release' );
can_ok( $obj, 'status' );
can_ok( $obj, 'version' );

is( $obj->checksum_md5, $test_data->{checksum_md5}, 'checksum_md5' );
is( $obj->checksum_sha256, $test_data->{checksum_sha256}, 'checksum_sha256' );
$this = $obj->date;
is( $this => $test_data->{date}, 'date' );
if( defined( $test_data->{date} ) )
{
    isa_ok( $this => 'DateTime', 'date returns a DateTime object' );
}
$this = $obj->download_url;
is( $this => $test_data->{download_url}, 'download_url' );
if( defined( $test_data->{download_url} ) )
{
    isa_ok( $this => 'URI', 'download_url returns an URI object' );
}
is( $obj->release, $test_data->{release}, 'release' );
is( $obj->status, $test_data->{status}, 'status' );
$this = $obj->version;
is( $this, $test_data->{version}, 'version' );

done_testing();

__END__
{
   "checksum_md5" : "71682907d95a4b0a4b74da8c16e88d2d",
   "checksum_sha256" : "27d4da9e772bc1922618b36fdefa768344d92c3d65a5e3cc427218cfc8d7491d",
   "date" : "2023-07-29T05:10:12",
   "download_url" : "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO/Folklore-Japan-v1.2.3.tar.gz",
   "release" : "Folklore-Japan-v1.2.3",
   "status" : "latest",
   "version" : "v1.2.3",
}
