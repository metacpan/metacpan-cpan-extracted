use strict;
use warnings;
use ExtUtils::MakeMaker;

require 5.006;

WriteMakefile(
              NAME                => 'Module::Checkstyle',
              AUTHOR              => 'Claes Jacobsson <claesjac@cpan.org>',
              VERSION_FROM        => 'lib/Module/Checkstyle.pm',
              ABSTRACT_FROM       => 'lib/Module/Checkstyle.pm',
              EXE_FILES           => ['bin/module-checkstyle'],
              PREREQ_PM           => {
                                      'Carp'                        => 0,
                                      'Config::Tiny'                => 0,
                                      'File::Find::Rule'            => 0,
                                      'File::HomeDir'               => 0,
                                      'File::Spec'                  => 0,
                                      'Getopt::Long'                => 0,
                                      'Lingua::EN::Inflect::Number' => 0,
                                      'List::Util'                  => 0,
                                      'Module::Pluggable'           => 0,
                                      'PPI'                         => 1.00,
                                      'Pod::Usage'                  => 0,
                                      'Readonly'                    => 0,
                                  },
              dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              clean               => { FILES => 'Module-Checkstyle-*' },
          );
