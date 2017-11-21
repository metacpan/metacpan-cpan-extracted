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

subtest 'basic' => sub {
    my $got = $scanner->scan_file(catfile($FindBin::Bin, 'resources', 'v_string.pl'));
    cmp_deeply(get_reqs_hash($got), {
        'File::Temp' => any('v0.1_2', 'v0.12.0')
    });
};

done_testing;
