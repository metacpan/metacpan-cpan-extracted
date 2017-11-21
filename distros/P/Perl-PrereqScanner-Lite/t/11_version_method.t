#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/..";

use File::Spec::Functions qw/catfile/;
use Perl::PrereqScanner::Lite;

use t::Util;
use Test::More;
use Test::Deep;

my $scanner = Perl::PrereqScanner::Lite->new;
$scanner->add_extra_scanner('Version');

my $got = $scanner->scan_file(catfile($FindBin::Bin, 'resources', 'version.pl'));
cmp_deeply(get_reqs_hash($got), {
    strict         => 0,
    warnings       => 0,
    POSIX          => 1,
    Fnctrl         => '1.00',
    Carp           => 'v1.0.0',
});

done_testing;

