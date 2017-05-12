######################################################################
# Test suite for Perl::Installed
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;

my $ntests = 3;

use Test::More;
plan tests => $ntests;

use Perl::Installed;

eval { my $pe = Perl::Installed->new(); };

if($@) {
    like($@, qr/prefix/, "Checking for prefix");
} else {
    ok(0, "prefix check failed");
}

SKIP: {
    my @dirs = qw(/usr /usr/local);
    my $prefix;
    for (@dirs) {
        if(-f "$_/bin/perl") {
            $prefix = $_;
            last;
        }
    }
    if(! defined $prefix) {
        skip "no perl installation found in usual places", $ntests - 1;
    }

    my $pe = Perl::Installed->new( prefix => $prefix );
    my $cfg = $pe->config();

    like $cfg->{version}, qr/\d/, "version contains a number";

    my $files = $pe->files();
    if(! defined $files) {
        skip "no .packfile found", $ntests - 2;
    }

    my($first) = @$files;
    if($first->{path} !~ /^$prefix/) {
        skip "Different prefix in .packfile", $ntests - 2;
    }

    my($perl_exe) = grep { $_->{path} eq "$prefix/bin/perldoc" } @$files;
    is($perl_exe->{type}, "file", "perldoc file test");
}
