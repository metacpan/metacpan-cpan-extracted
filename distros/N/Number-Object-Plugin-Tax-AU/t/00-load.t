#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Number::Object::Plugin::Tax::AU::GST' );
}

diag( "Testing Number::Object::Plugin::Tax::AU::GST $Number::Object::Plugin::Tax::AU::GST::VERSION, Perl $], $^X" );
