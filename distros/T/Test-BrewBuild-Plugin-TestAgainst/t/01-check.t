#!/usr/bin/perl
use 5.006;
use strict;
use warnings;

use Test::BrewBuild::Plugin::TestAgainst;
use Test::More;

my $mod = 'Test::BrewBuild::Plugin::TestAgainst';

can_ok ($mod, 'brewbuild_exec');

my @ret = $mod->brewbuild_exec('', 'Mock::Sub');

my @data = <DATA>;

is (@data, @ret, "the return from $mod ok");

my $i = 0;

for (@data){
    s/%\[MODULE\]%/Mock::Sub/g;
    is ($ret[$i], $_, "$_ line matches baseline");
    $i++;
}

done_testing();

__DATA__
cpan App::cpanminus
cpanm --installdeps .
cpanm .
cpanm --test-only %[MODULE]%
