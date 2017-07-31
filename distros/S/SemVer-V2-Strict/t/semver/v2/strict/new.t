use strict;
use warnings;
use utf8;

use Test::Mock::Guard qw/mock_guard/;

use lib '.';
use t::Util;
use SemVer::V2::Strict;

subtest basic => sub {
    subtest '# 0' => sub {
        my $guard = mock_guard('SemVer::V2::Strict', {
            _init_by_version_numbers => sub { is @_, 1 },
            _init_by_version_string  => sub { },
        });

        SemVer::V2::Strict->new;

        is $guard->call_count('SemVer::V2::Strict', '_init_by_version_numbers'), 1;
        is $guard->call_count('SemVer::V2::Strict', '_init_by_version_string'),  0;
    };

    subtest '# 1' => sub {
        my $guard = mock_guard('SemVer::V2::Strict', {
            _init_by_version_numbers => sub { },
            _init_by_version_string  => sub {
                isa_ok $_[0], 'SemVer::V2::Strict';
                is     $_[1], '1.2.3';
            },
        });

        SemVer::V2::Strict->new('1.2.3');

        is $guard->call_count('SemVer::V2::Strict', '_init_by_version_numbers'), 0;
        is $guard->call_count('SemVer::V2::Strict', '_init_by_version_string'),  1;
    };

    subtest '# > 2' => sub {
        my $guard = mock_guard('SemVer::V2::Strict', {
            _init_by_version_numbers => sub {
                isa_ok shift, 'SemVer::V2::Strict';
                cmp_deeply [ @_ ], [ 1, 2, 3, 'alpha', '100' ];
            },
            _init_by_version_string  => sub { },
        });

        SemVer::V2::Strict->new(1, 2, 3, 'alpha', '100');

        is $guard->call_count('SemVer::V2::Strict', '_init_by_version_numbers'), 1;
        is $guard->call_count('SemVer::V2::Strict', '_init_by_version_string'),  0;
    };
};

done_testing;
