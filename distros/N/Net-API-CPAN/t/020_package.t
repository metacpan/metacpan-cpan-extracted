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
    use_ok( 'Net::API::CPAN::Package' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Package->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Package' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Package->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Package.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'author' );
can_ok( $obj, 'dist_version' );
can_ok( $obj, 'distribution' );
can_ok( $obj, 'file' );
can_ok( $obj, 'module_name' );
can_ok( $obj, 'object' );
can_ok( $obj, 'version' );

is( $obj->author, $test_data->{author}, 'author' );
$this = $obj->dist_version;
is( $this, $test_data->{dist_version}, 'dist_version' );
is( $obj->distribution, $test_data->{distribution}, 'distribution' );
is( $obj->file, $test_data->{file}, 'file' );
is( $obj->module_name, $test_data->{module_name}, 'module_name' );
$this = $obj->version;
is( $this => $test_data->{version}, 'version' );
if( defined( $test_data->{version} ) )
{
    isa_ok( $this => 'Module::Generic::Number', 'version returns a number object' );
}

done_testing();

__END__
{
   "distribution" : "Folklore-Japan",
   "author" : "MOMOTARO",
   "version" : "1.002003",
   "dist_version" : "v1.2.3",
   "file" : "M/MO/MOMOTARO/Folklore-Japan-v1.2.3.tar.gz",
   "module_name" : "Folklore::Japan"
}
