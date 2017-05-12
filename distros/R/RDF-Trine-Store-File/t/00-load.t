use Test::More tests => 1;

BEGIN {
    use_ok( 'RDF::Trine::Store::File' ) || print "Bail out!\n";
}

diag( "Testing RDF::Trine::Store::File $RDF::Trine::Store::File::VERSION, Perl $], $^X" );
