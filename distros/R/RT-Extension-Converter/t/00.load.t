use Test::More tests => 6;

BEGIN {
use_ok( 'RT::Extension::Converter' );
use_ok( 'RT::Extension::Converter::Config' );
use_ok( 'RT::Extension::Converter::RT1' );
use_ok( 'RT::Extension::Converter::RT1::Config' );
use_ok( 'RT::Extension::Converter::RT3' );
use_ok( 'RT::Extension::Converter::RT3::Config' );
}

diag( "Testing RT::Extension::Converter $RTx::Converter::VERSION" );
