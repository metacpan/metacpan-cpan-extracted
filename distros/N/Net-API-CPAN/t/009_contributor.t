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
    use_ok( 'Net::API::CPAN::Contributor' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Contributor->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Contributor' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Contributor->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Contributor.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'distribution' );
can_ok( $obj, 'object' );
can_ok( $obj, 'pauseid' );
can_ok( $obj, 'release_author' );
can_ok( $obj, 'release_name' );

is( $obj->distribution, $test_data->{distribution}, 'distribution' );
is( $obj->pauseid, $test_data->{pauseid}, 'pauseid' );
is( $obj->release_author, $test_data->{release_author}, 'release_author' );
is( $obj->release_name, $test_data->{release_name}, 'release_name' );

done_testing();

__END__
{}
