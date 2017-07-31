use strict;
use warnings;
use utf8;

use lib '.';
use t::Util;
use SemVer::V2::Strict;

subtest basic => sub {
    my %versions = (
        '1.2.3'        => '1.2.3',
        '1.2.3'        => '1.2.3',
        ' 1.2.3 '      => '1.2.3',
        ' 1.2.3-4 '    => '1.2.3-4',
        ' 1.2.3-pre '  => '1.2.3-pre',
        '  =v1.2.3   ' => '1.2.3',
        'v1.2.3'       => '1.2.3',
        ' v1.2.3 '     => '1.2.3',
        "\t1.2.3"      => '1.2.3',
        '>1.2.3'       => undef,
        '~1.2.3'       => undef,
        '<=1.2.3'      => undef,
        '1.2.x'        => undef,
    );

    while (my ($version, $expected) = each %versions) {
        my $actual = SemVer::V2::Strict->clean($version);
        is $actual, $expected;
    }
};

done_testing;
