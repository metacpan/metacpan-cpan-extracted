use strict;
use warnings;
use utf8;

use t::Util;
use SemVer::V2::Strict;

sub create_instance { bless {} => 'SemVer::V2::Strict' }

subtest basic => sub {
    my $version = create_instance;
    $version->_init_by_version_numbers(1, 2, 3, 'alpha', '100');

    is $version->major, 1;
    is $version->minor, 2;
    is $version->patch, 3;
    is $version->pre_release,    'alpha';
    is $version->build_metadata, '100';
};

done_testing;
