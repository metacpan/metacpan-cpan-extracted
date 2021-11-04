#!/usr/bin/perl
use Test::More tests => 16;

BEGIN {
    use_ok( "Module::Generic" );
    use_ok( "Module::Generic::Exception" );
    use_ok( "Module::Generic::Number" );
    use_ok( "Module::Generic::Scalar" );
    use_ok( "Module::Generic::Null" );
    use_ok( "Module::Generic::TieHash" );
    use_ok( "Module::Generic::Boolean" );
    use_ok( "Module::Generic::Iterator" );
    use_ok( "Module::Generic::File" );
    use_ok( "Module::Generic::Dynamic" );
    use_ok( "Module::Generic::Hash" );
    use_ok( "Module::Generic::SharedMem" );
    use_ok( "Module::Generic::Array" );
    use_ok( "Module::Generic::DateTime" );
    use_ok( "Module::Generic::Finfo" );
    use_ok( "Module::Generic::Tie" );
}
