
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Task::Metabase',
                       'DISTNAME' => 'Task-Metabase',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'David Golden <dagolden@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Install Metabase server related modules',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100760',
                       'PREREQ_PM' => {
                                        'CPAN::Testers::Metabase' => '1.999',
                                        'Metabase::Client::Simple' => '0.005',
                                        'JSON::XS' => '2.00',
                                        'CPAN::Testers::Common::Utils' => '0.001',
                                        'CPAN::Testers::Report' => '1.999',
                                        'Metabase' => '0.005',
                                        'Metabase::Fact' => '0.006'
                                      },
                       'LICENSE' => 'apache'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



