#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Module::Format' );
    use_ok( 'Module::Format::Module' );
    use_ok( 'Module::Format::ModuleList' );
}

diag( "Testing Module::Format $Module::Format::VERSION, Perl $], $^X" );
