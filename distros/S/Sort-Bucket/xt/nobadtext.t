# Check for some things that shouldn't be in release quality code.

use strict;
use warnings;

use autodie;
use Test::More;
use File::Find::Rule;
use File::Slurp;

my @files = File::Find::Rule->file()->in(qw(
    Build.PL lib t xt Changes MANIFEST.SKIP README xMakefile
));

plan tests => scalar @files;

foreach my $file (@files) {
    my @bad;
    open my $fh, "<", $file;
    while (<$fh>) {
        unless ($file eq "xt/nobadtext.t") {
            /FIXME/ and push @bad, "FIXME at line $.";
            /XXX/   and push @bad, "XXX at line $.";
        }
        /^\s*\#.*;\s*$/ and push @bad, "commented out code at line $.";
        /^\s*warn\b/    and push @bad, "warn at line $.";

        if ($file eq "Changes") {
            /\?\?\?/ and push @bad, "??? on line $.";
        }
    }
    unless ( ok @bad == 0, "no bad text in $file" ) {
        foreach my $bad (@bad) {
            diag $bad;
        }
    }
}

