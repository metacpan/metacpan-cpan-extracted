#!perl -T

use Test::Most;

BEGIN {
    use_ok( 'OpusVL::SysParams' ) || print "Bail out!
";
}

diag( "Testing OpusVL::SysParams $OpusVL::SysParams::VERSION, Perl $], $^X" );

#use_ok 'OpusVL::SysParams::RolesFor::Schema';
use_ok 'OpusVL::SysParams::Schema::Result::SysInfo';
use_ok 'OpusVL::SysParams::Schema';

done_testing;
