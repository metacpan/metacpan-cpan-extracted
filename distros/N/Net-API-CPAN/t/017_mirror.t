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
    use_ok( 'Net::API::CPAN::Mirror' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Mirror->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Mirror' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Mirror->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Mirror.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'A_or_CNAME' );
can_ok( $obj, 'aka_name' );
can_ok( $obj, 'ccode' );
can_ok( $obj, 'city' );
can_ok( $obj, 'contact' );
can_ok( $obj, 'continent' );
can_ok( $obj, 'country' );
can_ok( $obj, 'distance' );
can_ok( $obj, 'dnsrr' );
can_ok( $obj, 'freq' );
can_ok( $obj, 'ftp' );
can_ok( $obj, 'http' );
can_ok( $obj, 'inceptdate' );
can_ok( $obj, 'location' );
can_ok( $obj, 'name' );
can_ok( $obj, 'note' );
can_ok( $obj, 'object' );
can_ok( $obj, 'org' );
can_ok( $obj, 'region' );
can_ok( $obj, 'reitredate' );
can_ok( $obj, 'rsync' );
can_ok( $obj, 'src' );
can_ok( $obj, 'tz' );

is( $obj->A_or_CNAME, $test_data->{A_or_CNAME}, 'A_or_CNAME' );
is( $obj->aka_name, $test_data->{aka_name}, 'aka_name' );
is( $obj->ccode, $test_data->{ccode}, 'ccode' );
is( $obj->city, $test_data->{city}, 'city' );
$this = $obj->contact;
isa_ok( $this => 'Module::Generic::Array', 'contact returns an array object' );
is( $obj->continent, $test_data->{continent}, 'continent' );
is( $obj->country, $test_data->{country}, 'country' );
is( $obj->distance, $test_data->{distance}, 'distance' );
is( $obj->dnsrr, $test_data->{dnsrr}, 'dnsrr' );
is( $obj->freq, $test_data->{freq}, 'freq' );
$this = $obj->ftp;
is( $this => $test_data->{ftp}, 'ftp' );
if( defined( $test_data->{ftp} ) )
{
    isa_ok( $this => 'URI', 'ftp returns an URI object' );
}
$this = $obj->http;
is( $this => $test_data->{http}, 'http' );
if( defined( $test_data->{http} ) )
{
    isa_ok( $this => 'URI', 'http returns an URI object' );
}
$this = $obj->inceptdate;
is( $this => $test_data->{inceptdate}, 'inceptdate' );
if( defined( $test_data->{inceptdate} ) )
{
    isa_ok( $this => 'DateTime', 'inceptdate returns a DateTime object' );
}
$this = $obj->location;
ok( ( Scalar::Util::reftype( $this ) eq 'ARRAY' && Scalar::Util::blessed( $this ) ), 'location returns an array object' );
if( defined( $test_data->{location} ) )
{
    ok( scalar( @$this ) == scalar( @{$test_data->{location}} ), 'location -> array size matches' );
    for( my $i = 0; $i < @$this; $i++ )
    {
        is( $this->[$i], $test_data->{location}->[$i], 'location -> value offset $i' );
    }
}
else
{
    ok( !scalar( @$this ), 'location -> array is empty' );
}
is( $obj->name, $test_data->{name}, 'name' );
is( $obj->note, $test_data->{note}, 'note' );
is( $obj->org, $test_data->{org}, 'org' );
is( $obj->region, $test_data->{region}, 'region' );
$this = $obj->reitredate;
is( $this => $test_data->{reitredate}, 'reitredate' );
if( defined( $test_data->{reitredate} ) )
{
    isa_ok( $this => 'DateTime', 'reitredate returns a DateTime object' );
}
$this = $obj->rsync;
is( $this => $test_data->{rsync}, 'rsync' );
if( defined( $test_data->{rsync} ) )
{
    isa_ok( $this => 'URI', 'rsync returns an URI object' );
}
$this = $obj->src;
is( $this => $test_data->{src}, 'src' );
if( defined( $test_data->{src} ) )
{
    isa_ok( $this => 'URI', 'src returns an URI object' );
}
is( $obj->tz, $test_data->{tz}, 'tz' );

done_testing();

__END__
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
