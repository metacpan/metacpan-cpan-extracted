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
    use_ok( 'Net::API::CPAN::Author' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Author->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Author' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Author->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Author.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'asciiname' );
can_ok( $obj, 'blog' );
can_ok( $obj, 'city' );
can_ok( $obj, 'country' );
can_ok( $obj, 'dir' );
can_ok( $obj, 'donation' );
can_ok( $obj, 'email' );
can_ok( $obj, 'gravatar_url' );
can_ok( $obj, 'is_pause_custodial_account' );
can_ok( $obj, 'links' );
can_ok( $obj, 'location' );
can_ok( $obj, 'metacpan_url' );
can_ok( $obj, 'name' );
can_ok( $obj, 'object' );
can_ok( $obj, 'pauseid' );
can_ok( $obj, 'perlmongers' );
can_ok( $obj, 'profile' );
can_ok( $obj, 'region' );
can_ok( $obj, 'release_count' );
can_ok( $obj, 'releases' );
can_ok( $obj, 'updated' );
can_ok( $obj, 'user' );
can_ok( $obj, 'website' );

is( $obj->asciiname, $test_data->{asciiname}, 'asciiname' );
$this = $obj->blog;
isa_ok( $this => 'Module::Generic::Array', 'blog returns an array object' );
is( $obj->city, $test_data->{city}, 'city' );
is( $obj->country, $test_data->{country}, 'country' );
$this = $obj->donation;
isa_ok( $this => 'Module::Generic::Array', 'donation returns an array object' );
$this = $obj->email;
isa_ok( $this => 'Module::Generic::Array', 'email returns an array object' );
$this = $obj->gravatar_url;
is( $this => $test_data->{gravatar_url}, 'gravatar_url' );
if( defined( $test_data->{gravatar_url} ) )
{
    isa_ok( $this => 'URI', 'gravatar_url returns an URI object' );
}
$this = $obj->is_pause_custodial_account;
if( defined( $test_data->{is_pause_custodial_account} ) )
{
    is( $this => $test_data->{is_pause_custodial_account}, 'is_pause_custodial_account returns a boolean value' );
}
else
{
    ok( !$this, 'is_pause_custodial_account returns a boolean value' );
}
$this = $obj->links;
ok( Scalar::Util::blessed( $this ), 'links returns a dynamic class' );
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
is( $obj->pauseid, $test_data->{pauseid}, 'pauseid' );
$this = $obj->perlmongers;
isa_ok( $this => 'Module::Generic::Array', 'perlmongers returns an array object' );
$this = $obj->profile;
isa_ok( $this => 'Module::Generic::Array', 'profile returns an array object' );
is( $obj->region, $test_data->{region}, 'region' );
$this = $obj->release_count;
ok( Scalar::Util::blessed( $this ), 'release_count returns a dynamic class' );
$this = $obj->updated;
is( $this => $test_data->{updated}, 'updated' );
if( defined( $test_data->{updated} ) )
{
    isa_ok( $this => 'DateTime', 'updated returns a DateTime object' );
}
is( $obj->user, $test_data->{user}, 'user' );
$this = $obj->website;
isa_ok( $this => 'Module::Generic::Array', 'website returns an array object' );

done_testing();

__END__
{
   "asciiname" : "Taro Momo",
   "blog" : [
      {
         "feed" : "",
         "url" : "https://momotaro.example.jp/"
      },
      {
         "feed" : "https://blogs.perl.org/users/momotaro/atom.xml",
         "url" : "https://blogs.perl.org/users/momotaro/"
      },
   ],
   "city" : "Okayama",
   "country" : "JP",
   "donation" : [
      {
         "name" : "stripe",
         "id" : "momo.taro@example.jp"
      }
   ],
   "perlmongers": [
      {
         "name": "momo.taro"
      }
   ],
   "email" : [
      "momo.taro@example.jp"
   ],
   "gravatar_url" : "https://secure.gravatar.com/avatar/a123abc456def789ghi0jkl?s=130&d=identicon",
   "links" : {
      "backpan_directory" : "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO",
      "cpan_directory" : "http://cpan.org/authors/id/M/MO/MOMOTARO",
      "cpantesters_matrix" : "http://matrix.cpantesters.org/?author=MOMOTARO",
      "cpantesters_reports" : "http://cpantesters.org/author/M/MOMOTARO.html",
      "cpants" : "http://cpants.cpanauthors.org/author/MOMOTARO",
      "metacpan_explorer" : "https://explorer.metacpan.org/?url=/author/MOMOTARO",
      "repology" : "https://repology.org/maintainer/MOMOTARO%40cpan"
   },
   "location" : [
      34.7338553,
      133.7660595
   ],
   "name" : "桃太郎",
   "pauseid" : "MOMOTARO",
   "profile" : [
      {
         "id" : "momotaro",
         "name" : "coderwall"
      },
      {
         "id" : "momotaro",
         "name" : "github"
      },
      {
         "id" : "momotaro",
         "name" : "linkedin"
      },
      {
         "id" : "momotaro",
         "name" : "twitter"
      },
      {
         "id" : "momotaro",
         "name" : "gitlab"
      }
   ],
   "region" : "Okayama",
   "release_count" : {
      "backpan-only" : 12,
      "cpan" : 420,
      "latest" : 17
   },
   "updated" : "2023-07-29T04:45:10",
   "user" : "j_20ap7aNOkaYA11m9a2",
   "website" : [
      "https://www.momotaro.jp/"
   ]
}
