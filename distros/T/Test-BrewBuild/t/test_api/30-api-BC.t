#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Logging::Simple;
use Test::BrewBuild::BrewCommands;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

if (! $ENV{PERLVER}){
    plan skip_all => "\$ENV{PERLVER} is not set!";
    exit;
}

my $perlver = $ENV{PERLVER};

my $im_on_windows = ($^O =~ /MSWin/) ? 1 : 0;

my $log = Logging::Simple->new;
my $bc = Test::BrewBuild::BrewCommands->new($log);

is (ref $bc, 'Test::BrewBuild::BrewCommands', 'obj is ok');

if ($im_on_windows){

   like ($bc->brew, qr/berrybrew\.exe/, "win: brew() is ok");

   my $inst = '5.20.3_64       [installed]';
   my @inst = $bc->installed(0, $inst);
   is ($inst[0], "5.20.3_64", "win: installed is ok");

   my $avail = "${perlver}_64";
   my @avail = $bc->available(0, $avail);
   is ($avail[0], "${perlver}_64", "win: avail with info ok");

   my $inst_cmd = $bc->install;
   like ($inst_cmd, qr/berrybrew\.exe install/, "win: install() ok");

   my $remove_cmd = $bc->remove;
   like ($remove_cmd, qr/berrybrew\.exe remove/, "win: remove() ok");

   is ($bc->is_win, 1, "win: is win ok");
}
else {
    is ($bc->brew, 'perlbrew', "nix: brew() is ok");

    my $inst = "i perl-$perlver";
    my @inst = $bc->installed(0, $inst);
    is ($inst[0], "perl-$perlver", "nix: installed is ok");

    my $avail = "perl-$perlver";
    my @avail = $bc->available(0, $avail);
    is ($avail[0], "perl-$perlver", "nix: avail with info ok");

    my $inst_cmd = $bc->install;
    is ($inst_cmd, 'perlbrew install --notest -j 4', "nix: install() ok");

    my $remove_cmd = $bc->remove;
    is ($remove_cmd, 'perlbrew --yes uninstall', "nix: remove() ok");

    is ($bc->is_win, 0, "nix: is win ok");
}

{ # info cache

    my $info;

    is 
        defined $bc->{info_cache}, 
        '', 
        "no cache before first call to info_cache()";

    $info = $bc->info_cache;

    is 
        defined $bc->{info_cache}, 
        1, 
        "cache ok on subsequent call to info_cache()";

    $info = $bc->info_cache;

    like $info, qr/\d\.\d{2}/, "info_cache() returns data";
}

SKIP: { # legacy off (issue #137)

    my $legacy = 0;
    my $info = $bc->info;

    skip "no legacy versions installed", 1 if $info !~ /5\.6\.2/;

    my @avail = $bc->available($legacy, $info);

    my $ok = grep /5\.6\.2/, @avail;

    is ($ok, 0, "legacy disabled ok");
}

SKIP: { # legacy on (issue #137)

    my $legacy = 1;
    my $info = $bc->info;

    skip "no legacy versions installed", 1 if $info !~ /5\.6\.2/;

    my @avail = $bc->available($legacy, $info);

    my $ok = grep /5\.6\.2/, @avail;

    is ($ok, 1, "legacy enabled ok");
}

done_testing();

