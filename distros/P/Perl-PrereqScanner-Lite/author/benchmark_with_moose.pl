#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use autodie;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Perl::PrereqScanner;
use Perl::PrereqScanner::Lite;
use Benchmark qw(cmpthese);

my $filename = "$FindBin::Bin/../lib/Perl/PrereqScanner/Lite.pm";
print "target file: $filename\n";

my $c1 = sub {
    my $p = Perl::PrereqScanner::Lite->new;
    $p->add_extra_scanner('Moose');
    $p->scan_file($filename);
};

my $c2 = sub {
    my $p = Perl::PrereqScanner->new;
    $p->scan_file($filename);
};

cmpthese(
    -1 => {
        'Perl::PrereqScanner::Lite' => $c1,
        'Perl::PrereqScanner' => $c2,
    },
);
