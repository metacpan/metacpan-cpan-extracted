#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;

skip_all("Test only for AUTHOR testing") unless $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};

my $exdir = "$FindBin::Bin/../examples";
ok -d $exdir, "examples directory exist";

my @files;
if ( opendir( my $dh, $exdir ) ) {
    @files = sort { lc $a cmp lc $b }
      grep { m/\.(?:t|pl)$/ }
      grep { !/^\.+$/ } readdir($dh);
}

ok scalar @files, "got some files" or die;

foreach my $f (@files) {
    my $path = $exdir . '/' . $f;
    my $out;
    $out = qx{$^X -I../lib -I../blib -cw $path 2>&1};
    is $?, 0, "perl -cw examples/$f" or do { diag $out; next };

    $out = qx{$^X -I../lib -I../blib $path 2>&1};
    is $?, 0, "perl examples/$f" or diag $out;
}

done_testing;
