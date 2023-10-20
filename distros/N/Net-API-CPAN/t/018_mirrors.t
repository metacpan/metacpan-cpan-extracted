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
    use_ok( 'Net::API::CPAN::Mirrors' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Mirrors->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Mirrors' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Mirrors->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Mirrors.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'mirrors' );
can_ok( $obj, 'object' );
can_ok( $obj, 'took' );
can_ok( $obj, 'total' );

$this = $obj->mirrors;
isa_ok( $this => 'Module::Generic::Array', 'mirrors returns an array object' );
$this = $obj->took;
is( $this => $test_data->{took}, 'took' );
if( defined( $test_data->{took} ) )
{
    isa_ok( $this => 'Module::Generic::Number', 'took returns a number object' );
}
$this = $obj->total;
is( $this => $test_data->{total}, 'total' );
if( defined( $test_data->{total} ) )
{
    isa_ok( $this => 'Module::Generic::Number', 'total returns a number object' );
}

done_testing();

__END__
{
   "mirrors" : [
      {
         "ccode" : "zz",
         "city" : "Everywhere",
         "contact" : [
            {
               "contact_site" : "perl.org",
               "contact_user" : "cpan"
            }
         ],
         "continent" : "Global",
         "country" : "Global",
         "distance" : null,
         "dnsrr" : "N",
         "freq" : "instant",
         "http" : "http://www.cpan.org/",
         "inceptdate" : "2021-04-09T00:00:00",
         "location" : [
            0,
            0
         ],
         "name" : "www.cpan.org",
         "org" : "Global CPAN CDN",
         "src" : "rsync://cpan-rsync.perl.org/CPAN/",
         "tz" : "0"
      }
   ],
   "took" : 2,
   "total" : 1
}
