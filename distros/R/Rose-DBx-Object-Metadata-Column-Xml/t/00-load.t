#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Rose::DBx::Object::Metadata::Column::Xml' ) || print "Bail out!
";
}

diag( "Testing Rose::DBx::Object::Metadata::Column::Xml $Rose::DBx::Object::Metadata::Column::Xml::VERSION, Perl $], $^X" );
