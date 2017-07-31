use strict;
use warnings;
use utf8;

use lib '.';
use t::Util;
use SemVer::V2::Strict;

sub create_instance { bless {} => 'SemVer::V2::Strict' }

subtest basic => sub {
    subtest '# major' => sub {
        my $version = create_instance();
        $version->_init_by_version_string('1');
        is $version->major, 1;
        is $version->minor, 0;
        is $version->patch, 0;
        is $version->pre_release,    undef;
        is $version->build_metadata, undef;
    };

    subtest '# minor' => sub {
        my $version = create_instance();
        $version->_init_by_version_string('1.2');
        is $version->major, 1;
        is $version->minor, 2;
        is $version->patch, 0;
        is $version->pre_release,    undef;
        is $version->build_metadata, undef;
    };

    subtest '# patch' => sub {
        my $version = create_instance();
        $version->_init_by_version_string('1.2.3');
        is $version->major, 1;
        is $version->minor, 2;
        is $version->patch, 3;
        is $version->pre_release,    undef;
        is $version->build_metadata, undef;
    };

    subtest '# pre_release' => sub {
        my $version = create_instance();
        $version->_init_by_version_string('1.2.3-alpha');
        is $version->major, 1;
        is $version->minor, 2;
        is $version->patch, 3;
        is $version->pre_release,    'alpha';
        is $version->build_metadata, undef;
    };

    subtest '# build_metadata' => sub {
        my $version = create_instance();
        $version->_init_by_version_string('1.2.3-alpha+001');
        is $version->major, 1;
        is $version->minor, 2;
        is $version->patch, 3;
        is $version->pre_release,    'alpha';
        is $version->build_metadata, '001';
    };

    subtest '# die' => sub {
        my $version = create_instance();

        dies_ok(sub {
            $version->_init_by_version_string('');
        }, 'should die because arguments is empty string');

        dies_ok(sub {
            $version->_init_by_version_string('###.invalid.format.###');
        }, 'should die because arguments is invalid');
    };
};

done_testing;
