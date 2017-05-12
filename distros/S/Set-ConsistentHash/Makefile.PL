use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'          => 'Set::ConsistentHash',
              'VERSION_FROM'  => 'lib/Set/ConsistentHash.pm',
              'PREREQ_PM'     => {
                  'Digest::SHA1' => 0,
              },
              ABSTRACT_FROM => 'lib/Set/ConsistentHash.pm',
              AUTHOR     => 'Brad Fitzpatrick <brad@danga.com>',
              );
