use strict;
use warnings;
use utf8;

use Test::Mock::Guard qw/mock_guard/;

use t::Util;
use SemVer::V2::Strict;

subtest basic => sub {
    subtest '# major' => sub {
        my $version = SemVer::V2::Strict->new('1');
        is $version->as_string, '1.0.0';
    };

    subtest '# minor' => sub {
        my $version = SemVer::V2::Strict->new('1.2');
        is $version->as_string, '1.2.0';
    };

    subtest '# patch' => sub {
        my $version = SemVer::V2::Strict->new('1.2.3');
        is $version->as_string, '1.2.3';
    };

    subtest '# pre_release' => sub {
        my $version = SemVer::V2::Strict->new('1.2.3-alpha');
        is $version->as_string, '1.2.3-alpha';
    };

    subtest '# build_metadata' => sub {
        my $version = SemVer::V2::Strict->new('1.2.3-alpha+100');
        is $version->as_string, '1.2.3-alpha+100';
    };

    subtest '# overload' => sub {
        my $version = SemVer::V2::Strict->new('1.2.3-alpha+100');
        is $version, '1.2.3-alpha+100';
    };
};

done_testing;
