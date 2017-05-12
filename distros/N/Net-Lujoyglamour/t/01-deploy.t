#!perl 

use strict;
use warnings;

use Test::More qw( no_plan ); #Random initial string...
use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

use Net::Lujoyglamour;

my $dsn = 'dbi:SQLite:dbname=:memory:';
my $schema = Net::Lujoyglamour->connect($dsn);
$schema->deploy({ add_drop_tables => 1});

my $short = 1;
my $long = "uno.com/";
my $rs_url = $schema->resultset('Url');
my $new_url = $rs_url->new({ shortu=> $short,
			     longu => $long});
$new_url->insert;
my @all_urls = $rs_url->all;
is( $#all_urls, 0, "Length OK" );
is( $all_urls[0]->long_url, $long, "Result long retrieved" );
is( $all_urls[0]->short_url, $short, "Result short retrieved" );
my @valid_urls = qw( a aa aaa abcd ABCD AB_CD ABcdD _az_ );

push @valid_urls, "abcde_rst_uvwxyz";

my %used_urls;
for my $u ( @valid_urls ) {
  is( Net::Lujoyglamour::is_valid( $u), 1, "Valid URL $u" );
  $used_urls{$u} = 1;
}

my @invalid_urls = ( "a"x($Net::Lujoyglamour::short_url_size +1),
		     "!!!!",
		     "abcdñ",
		     "¿Qué pasa?" );

for my $u (@invalid_urls ) {
  is( Net::Lujoyglamour::is_valid( $u), '', "Invalid URL $u" );
}

for (1..100) {
  my $candidate;
  do {
      $candidate = $schema->generate_candidate_url
  } while $used_urls{$candidate};
  $used_urls{$candidate} = 1;
  like( $candidate, qr/[$Net::Lujoyglamour::valid_short_urls]+/, "$_ Candidate $candidate OK" );
  my $long_url = "this.is.a.long.url/".rand(1e6);
  $new_url =  $rs_url->new({ shortu=> $candidate,
			       longu => $long_url});
  $new_url->insert;
  my $url = $rs_url->single( { shortu=> $candidate } );
  is( $url->long_url, $long_url, "Got $long_url back" );
}

my $short_url;
for (1..100 ) {
  my $long_url = "this.is.a.long.url/".rand(1e6);
  $short_url = $schema->create_new_short( $long_url );
  like( $short_url, qr/[$Net::Lujoyglamour::valid_short_urls]+/, "Generated $short_url for $long_url OK" );
  my $this_long_url = $schema->get_long_for( $short_url );
  is( "http://$long_url", $this_long_url, "$_ Retrieved original" );
}

my @real_urls = (  "http://www.youtube.com/user/BubokVideos#p/u/6/l6cwGkW3vfs",
"http://lujoyglamour.tumblr.com/post/237071159/pjorge-muy-interesante-y-divertido-lujoyglamour-net",
		  "http://hardware.slashdot.org/story/10/01/15/028201/Robotics-Prof-Fears-Rise-of-Military-Robots?art_pos=3",
		  "http://www.lujoyglamour.es/2010/01/15/unos-cuantos-libros/",
    "http://search.twitter.com/search?q=lujoyglamour.net"
    );

for my $r (@real_urls) {
   $short_url = $schema->create_new_short( $r );
   is( $short_url ne '', 1 , "Getting $short_url for $r");
   my $this_long_url = $schema->get_long_for( $short_url );
   is( $r, $this_long_url, "Retrieved original $r" );
}

my @wanted = qw( this going what like );
for my $w (@wanted ) {
  my $long_url = "this.is.a.longer.url/".rand(1e6);
  $short_url = $schema->create_new_short( $long_url, $w );
  is( $short_url, $w, "Getting $w for $long_url");
}

eval {
    $schema->create_new_short('this.is.longer/qq', $wanted[0]);
};
like( $@, qr/URL/, "Error OK");

eval {
    $schema->create_new_short('!!!noURLhere!!!', "whatever");
};
like( $@, qr/URL/, "URL Error OK");

$short_url =  $schema->create_new_short('http://this.is.it', "whatever");
like( $short_url, qr/[$Net::Lujoyglamour::valid_short_urls]+/, "Generated $short_url from shaved URL OK" );

$short_url = $schema->create_new_short('http://this.is.it', "another");
like( $short_url, qr/[$Net::Lujoyglamour::valid_short_urls]+/, "Generated $short_url instead of another" );

