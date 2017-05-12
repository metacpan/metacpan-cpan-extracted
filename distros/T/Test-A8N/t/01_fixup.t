#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
use File::Copy;
use File::Path;
use File::Spec::Functions;

my @files = (
    't/cases/UI/Reports/Report_Dashboard.tc',
    't/cases/UI/Config/Certificates/Views_Root_CA.tc',
    't/cases/UI/Config/Accounts/Alert_Recipients.tc',
    't/cases/UI/Config/Accounts/Alert_Recipients.conf',
    't/cases/test_multiple.st',
    't/cases/test__with__spaces.tc',
    't/cases/System__Status/Basic__Status.tc',
    't/cases/test1.tc',
    't/cases/invalid_syntax.tc',
    't/cases/storytest.st',
);
plan tests => 2 + scalar(@files) * 3;

SKIP: {
    skip q{t/testdata/empty already exists}, 2 if (-d catdir(qw(t testdata empty)));
    ok(mkpath([catdir(qw(t testdata empty))]), q{mkdir t/testdata/empty});
    ok(-d catdir(qw(t testdata empty)), q{t/testdata/empty exists});
}

foreach my $file (@files) {
    my @f = split(m#/#, $file);
    my $new_file = $file;
    $new_file =~ s#^t/#t/testdata/#;
    $new_file =~ s/__/ /g;
    my @nf = split(m#/#, $new_file);
    my @nd = @nf[0 .. $#nf - 1];

    SKIP: {
        skip qq{"$new_file" already exists}, 3 if (-f catfile(@nf));
        SKIP: {
            skip qq{directory for "$new_file" already exists}, 2 if (-d catdir(@nd));
            ok(mkpath([catdir(@nd)]), q{make directory});
            ok(-d catdir(@nd), q{directory exists});
        }
        ok(copy(catfile(@f), catfile(@nf)), qq{copy file $file to testdata directory});
    }
}
