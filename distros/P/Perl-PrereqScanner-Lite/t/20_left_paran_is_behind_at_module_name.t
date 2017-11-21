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
# $scanner->add_extra_scanner('Version');

subtest 'basic' => sub {
    my $got = $scanner->scan_file(catfile($FindBin::Bin, 'resources', 'left_paren_is_behind_at_module_name', 'basic.pl'));
    cmp_deeply(get_reqs_hash($got), {
            'Const::Common' => 0,
        });
};

subtest 'with version' => sub {
    my $got = $scanner->scan_file(catfile($FindBin::Bin, 'resources', 'left_paren_is_behind_at_module_name', 'with_version.pl'));
    cmp_deeply(get_reqs_hash($got), {
            'Const::Common' => 0.01,
        });
};

done_testing;

