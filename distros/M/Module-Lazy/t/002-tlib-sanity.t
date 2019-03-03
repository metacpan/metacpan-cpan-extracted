#!perl

use strict;
use warnings;
use Test::More tests => 4;
use File::Basename qw(dirname);

@INC = grep { !m{\bt/lib$} } @INC;

ok_missing( "Module::Lazy::_::test::sample" );
ok_missing( "Module::Lazy::_::test::sample::missing" );

push @INC, dirname(__FILE__)."/lib";

ok_missing( "Module::Lazy::_::test::sample::missing" );
require_ok( "Module::Lazy::_::test::sample" )
    or print "Bail out! Module::Lazy::_::test::sample not present in Module::Lazy test kit\n";

sub ok_missing {
    my $module = shift;

    my $load = eval "require $module; 1"; ## no critic
    ok !$load, "no such module $module"
        or print "Bail out! Found $module in the wild\n";
};
