#!perl

use Test::More tests => 12;
use Sub::Identify ':all';

ok( !defined sub_name( undef ) );
ok( !defined sub_name( "scalar" ) );
ok( !defined sub_name( \"scalar ref" ) );
ok( !defined sub_name( \@INC ) );

ok( !defined stash_name( undef ) );
ok( !defined stash_name( "scalar" ) );
ok( !defined stash_name( \"scalar ref" ) );
ok( !defined stash_name( \@INC ) );

ok( !defined get_code_location( undef ) );
ok( !defined get_code_location( "scalar" ) );
ok( !defined get_code_location( \"scalar ref" ) );
ok( !defined get_code_location( \@INC ) );
