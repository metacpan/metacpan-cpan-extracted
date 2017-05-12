#!perl 

use Test::More tests => 4;

BEGIN {
    use_ok( 'POE::Component::DirWatch::Object' );
    use_ok( 'POE::Component::DirWatch::Object::NewFile' );
    use_ok( 'POE::Component::DirWatch::Object::Touched' );
    use_ok( 'POE::Component::DirWatch::Object::Untouched' );
}

diag( "Testing POE::Component::DirWatch::Object $POE::Component::DirWatch::Object::VERSION, Perl $], $^X" );
