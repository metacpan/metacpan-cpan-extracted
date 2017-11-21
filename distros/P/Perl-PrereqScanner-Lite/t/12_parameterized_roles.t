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

subtest 'test for moose parapeterized roles' => sub {
    my $scanner = Perl::PrereqScanner::Lite->new;
    $scanner->add_extra_scanner('Moose');

    my $got = $scanner->scan_file(catfile($FindBin::Bin, 'resources', 'moose_parameterized_roles.pl'));
    cmp_deeply(get_reqs_hash($got), {
        'Moose' => 0,
        'Dist::Zilla::Role::PrereqSource' => 0,
        'Dist::Zilla::Role::FileFinderUser' => 0,
        'Dist::Zilla::Role::FileFinderUser' => 0,
        'Dist::Zilla::Role::FileFinderUser' => 0,
    });
};

done_testing;

