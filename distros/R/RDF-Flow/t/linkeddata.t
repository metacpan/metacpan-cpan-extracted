use strict;
use warnings;

use Test::More;
use RDF::Flow qw(:all);
use RDF::Flow::LinkedData;

my $dbpedia = RDF::Flow::LinkedData->new(
    name => "DBPedia",
    match => sub {
        $_[0] =~ s{^http://en\.wikipedia\.org/wiki/}{http://dbpedia.org/resource/};
        return ($_[0] =~ qr{^http://dbpedia\.org/resource/.+});
    }
);

# mockup
my ($get_url, $env);
no warnings 'redefine';
local *RDF::Trine::Parser::parse_url_into_model = sub { $get_url = $_[1]; };

sub get {
  $env = { 'rdflow.uri' => shift };
  $get_url = undef;
  $dbpedia->retrieve( $env );
};

get( 'http://dbpedia.org/resource/Well-Tempered_Clavier' );
is( $get_url, 'http://dbpedia.org/resource/Well-Tempered_Clavier', 'dbpedia' );

get( 'http://example.org/' );
is( $get_url, undef, 'not dbpedia' );

get( 'http://dbpedia.org/resource/' );
is( $get_url, undef, 'not dbpedia' );

get( 'http://en.wikipedia.org/wiki/Well-Tempered_Clavier' );
is( $get_url, 'http://dbpedia.org/resource/Well-Tempered_Clavier', 'dbpedia' );

done_testing;
