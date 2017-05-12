#!/usr/bin/perl
use strict;
use warnings;

use Logging::Simple;
use Test::BrewBuild;
use Test::BrewBuild::BrewCommands;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $perlver = $ENV{PERLVER};

my $bb = Test::BrewBuild->new;
my $bcmd = Test::BrewBuild::BrewCommands->new( Logging::Simple->new );

if ($bcmd->is_win) {
    my $info = $bb->brew_info;
    print $info;
    my $using = $bcmd->using( $info );
    is ( $using, "${perlver}_64", "win: using() is ok" );
}
else {
    my $info = $bb->brew_info;
    my $using = $bcmd->using( $info );
    like ( $using, qr/perl-\d\.\d{1,2}\.\d/, "nix: using() is ok" );
}
done_testing();

