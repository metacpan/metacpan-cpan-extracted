use Test::More tests => 5;

BEGIN {
    use_ok('RDF::Sesame');
    use_ok('RDF::Sesame::Connection');
    use_ok('RDF::Sesame::Repository');
    use_ok('RDF::Sesame::Response');
    use_ok('RDF::Sesame::TableResult');
}

diag( "Testing RDF::Sesame $RDF::Sesame::VERSION" );
