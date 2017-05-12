#!/usr/bin/perl 

use strict;
use Test;
use File::Find;
use Term::ANSIColorx::ColorNicknames;

my @versions;

if ($ENV{TEST_AUTHOR}) {
    eval q ^
        use Path::Tiny;

        File::Find::find(sub {
            return unless -f $_;
            return if m/ColorNicknames\.pm/;
            my $cont = path($_)->slurp;
            my ($ver) = $cont =~ m/our\s*\$VERSION\s*=\s*['"](.+)['"]/;

            push @versions, [ $_, $ver ] if $ver;

        }, 'blib');
    ^;
}

if( @versions ) {
    plan tests => int @versions;
    ok( "@$_", "$_->[0] $Term::ANSIColorx::ColorNicknames::VERSION" ) for @versions;

} else {
    plan tests => 1;
    ok(1);
}
