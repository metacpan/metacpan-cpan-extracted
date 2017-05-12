use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec::Functions qw/catfile/;
use Perl::PrereqScanner::Lite;

use t::Util;
use Test::More;
use Test::Deep;

my $scanner = Perl::PrereqScanner::Lite->new;

subtest 'basic' => sub {
    my $got = $scanner->scan_file(catfile($FindBin::Bin, 'resources', 'v_string.pl'));
    cmp_deeply(get_reqs_hash($got), {
        'File::Temp' => 'v0.1_2',
    });
};

done_testing;

