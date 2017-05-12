#
# Copyright (c) 2015, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'OpenStack::Client',
    'VERSION_FROM' => 'lib/OpenStack/Client.pm',
    'AUTHOR'       => 'Alexandra Hrefna Hilmisdóttir <xan@cpanel.net>',
    'LICENSE'      => 'mit',
    'ABSTRACT'     => 'A nice and tiny OpenStack API client',

    'BUILD_REQUIRES' => {
        'JSON'           => 0,
        'HTTP::Request'  => 0,
        'LWP::UserAgent' => 0,
        'URI::Encode'    => 0
    },

    'TEST_REQUIRES' => {
        'Test::More'      => 0,
        'Test::Exception' => 0
    },

    'META_MERGE' => {
        'meta-spec' => {
            'version' => 2
        },

        'resources' => {
            'repository' => {
                'type' => 'git',
                'url'  => 'https://github.com/xantronix/openstack-client.git',
                'web'  => 'https://github.com/xantronix/openstack-client'
            }
        }
    }
);
