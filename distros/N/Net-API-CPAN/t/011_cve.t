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
    use_ok( 'Net::API::CPAN::Cve' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Cve->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Cve' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Cve->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Cve.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'affected_versions' );
can_ok( $obj, 'cpansa_id' );
can_ok( $obj, 'cves' );
can_ok( $obj, 'description' );
can_ok( $obj, 'distribution' );
can_ok( $obj, 'object' );
can_ok( $obj, 'references' );
can_ok( $obj, 'releases' );
can_ok( $obj, 'reported' );
can_ok( $obj, 'severity' );
can_ok( $obj, 'versions' );

is( $obj->affected_versions, $test_data->{affected_versions}, 'affected_versions' );
is( $obj->cpansa_id, $test_data->{cpansa_id}, 'cpansa_id' );
is( $obj->cves, $test_data->{cves}, 'cves' );
is( $obj->description, $test_data->{description}, 'description' );
is( $obj->distribution, $test_data->{distribution}, 'distribution' );
is( $obj->references, $test_data->{references}, 'references' );
is( $obj->releases, $test_data->{releases}, 'releases' );
$this = $obj->reported;
is( $this => $test_data->{reported}, 'reported' );
if( defined( $test_data->{reported} ) )
{
    isa_ok( $this => 'DateTime', 'reported returns a DateTime object' );
}
is( $obj->severity, $test_data->{severity}, 'severity' );
is( $obj->versions, $test_data->{versions}, 'versions' );

done_testing();

__END__
{}
