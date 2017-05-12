#!perl -T

use warnings;
use strict;
use Test::Config::System;

my @pkgmgrs = ('/usr/bin/dpkg', '/bin/rpm');
my $pkgmgr;

for my $path (@pkgmgrs) {
    (($pkgmgr) = $path =~ m|/([^/]+)$|, last) if (-x $path);
}

if ($pkgmgr) {
    plan(tests => 3);
    check_any_package(['this-is-a-bogus-packageeeee', 'perl'],
        'check_any_package(perl || bogus)' , 0, $pkgmgr);
    check_any_package(
        ['aoeuaoeuaoeuaoeu', 'im-screwed-if-someone-names-their-package-this',
            'but-thats-unlikely'],
       'inverted check_any_package', 1, $pkgmgr);
    check_any_package(['perl', 'this-is-bogus-package'],
        'check_any_package(bogus || perl)', 0, $pkgmgr);
} else {
    plan(skip_all =>
        'no suitable package manager found, skipping check_package tests');
}
