use Test::More; # tests => 23;

BEGIN {
  if( not not eval 'require JSON::Any' ) {
      plan tests => 23;
  }
  else {
      plan skip_all => 'JSON::Any required to test JSON formatting';
  }
  
  use_ok( 'RDF::Server::Formatter::JSON' );
}

use RDF::Server::Types qw( Exception );
eval "use Carp::Always"; # for those who don't have it

# this formatter does not want rdf
ok( !RDF::Server::Formatter::JSON -> wants_rdf );

# to_rdf should be the identity function
eval {
    RDF::Server::Formatter::JSON -> to_rdf( "{ }" );
};

ok( is_Exception( $@ ) );

my( $type, $json );

eval {
( $type, $json ) = RDF::Server::Formatter::JSON -> feed( );
};

is( $@, '', 'feed ran' );

is( $type, 'application/json' );
isnt( $json, '' );
isnt( $json, undef );

eval {
($type, $json ) = RDF::Server::Formatter::JSON -> category( );
};

is( $@, '', 'category ran' );
is( $type, 'application/json' );
isnt( $json, '' );
isnt( $json, undef );

eval {
($type, $json ) = RDF::Server::Formatter::JSON -> collection( );
};

is( $@, '', 'collection ran' );
is( $type, 'application/json' );
isnt( $json, '' );
isnt( $json, undef );

eval {
($type, $json ) = RDF::Server::Formatter::JSON -> workspace( );
};

is( $@, '', 'workspace ran' );
is( $type, 'application/json' );
isnt( $json, '' );
isnt( $json, undef );

eval {
($type, $json ) = RDF::Server::Formatter::JSON -> service( );
};

is( $@, '', 'service ran' );
is( $type, 'application/json' );
isnt( $json, '' );
isnt( $json, undef );

