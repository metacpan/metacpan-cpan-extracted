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
    use_ok( 'Net::API::CPAN::Cover' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Cover->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Cover' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Cover->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Cover.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'criteria' );
can_ok( $obj, 'distribution' );
can_ok( $obj, 'object' );
can_ok( $obj, 'release' );
can_ok( $obj, 'url' );
can_ok( $obj, 'version' );

$this = $obj->criteria;
ok( Scalar::Util::blessed( $this ), 'criteria returns a dynamic class' );
is( $obj->distribution, $test_data->{distribution}, 'distribution' );
is( $obj->release, $test_data->{release}, 'release' );
$this = $obj->url;
is( $this => $test_data->{url}, 'url' );
if( defined( $test_data->{url} ) )
{
    isa_ok( $this => 'URI', 'url returns an URI object' );
}
$this = $obj->version;
is( $this, $test_data->{version}, 'version' );

done_testing();

__END__
{
   "criteria" : {
      "branch" : "54.68",
      "total" : "67.65",
      "condition" : "57.56",
      "subroutine" : "80.00",
      "statement" : "78.14"
   },
   "version" : "v1.2.3",
   "distribution" : "Folklore-Japan",
   "url" : "http://cpancover.com/latest/Folklore-Japan-v1.2.3/index.html",
   "release" : "Folklore-Japan-v1.2.3"
}
