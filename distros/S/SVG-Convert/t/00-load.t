use Test::More tests => 2;

BEGIN {
    use_ok('SVG::Convert');
    use_ok('SVG::Convert::BaseDriver');
}

diag( "Testing SVG::Convert $SVG::Convert::VERSION" );
