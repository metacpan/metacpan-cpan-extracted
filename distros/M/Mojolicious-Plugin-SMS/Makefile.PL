require 5.008007;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile
(
          'NAME' => 'Mojolicious::Plugin::SMS',
          'VERSION_FROM' => 'lib/Mojolicious/Plugin/SMS.pm',
          'PREREQ_PM' => {
                           'Mojolicious' => '4.0',
                           'SMS::Send' => '0.04',
                           'Test::More' => 0
                         },
          'INSTALLDIRS' => 'site',
          'EXE_FILES' => [],
          'PL_FILES' => {},
          'META_MERGE' => {
                    'resources' => {
                              repository => {
                                        type => 'git',
                                        url  => 'https://github.com/ysyrota/mojolicious-plugin-sms.git',
                                        web  => 'https://github.com/ysyrota/mojolicious-plugin-sms',
                              },
                              bugtracker => {
                                        web => 'https://github.com/ysyrota/mojolicious-plugin-sms/issues',
                              },
                    },
          },
        )
;
