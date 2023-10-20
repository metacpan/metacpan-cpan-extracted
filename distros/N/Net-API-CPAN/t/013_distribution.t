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
    use_ok( 'Net::API::CPAN::Distribution' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Distribution->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Distribution' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Distribution->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Distribution.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'bugs' );
can_ok( $obj, 'external_package' );
can_ok( $obj, 'github' );
can_ok( $obj, 'metacpan_url' );
can_ok( $obj, 'name' );
can_ok( $obj, 'object' );
can_ok( $obj, 'river' );
can_ok( $obj, 'rt' );

$this = $obj->bugs;
ok( Scalar::Util::blessed( $this ), 'bugs returns a dynamic class' );
$this = $obj->external_package;
ok( Scalar::Util::blessed( $this ), 'external_package returns a dynamic class' );
is( $obj->name, $test_data->{name}, 'name' );
$this = $obj->river;
ok( Scalar::Util::blessed( $this ), 'river returns a dynamic class' );

done_testing();

__END__
{
   "bugs" : {
      "github" : {
         "active" : 5,
         "closed" : 10,
         "open" : 3,
         "source" : "https://github.com/momotaro/Folkore-Japan"
      },
      "rt" : {
         "active" : "2",
         "closed" : "18",
         "new" : 0,
         "open" : 2,
         "patched" : 0,
         "rejected" : 0,
         "resolved" : 18,
         "source" : "https://rt.cpan.org/Public/Dist/Display.html?Name=Folkore-Japan",
         "stalled" : 0
      }
   },
   "external_package" : {
      "cygwin" : "perl-Folkore-Japan",
      "debian" : "folklore-japan-perl",
      "fedora" : "perl-Folkore-Japan"
   },
   "name" : "Folklore-Japan",
   "river" : {
      "bucket" : 2,
      "bus_factor" : 1,
      "immediate" : 15,
      "total" : 19
   }
}
