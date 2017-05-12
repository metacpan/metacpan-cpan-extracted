use strict;
use Module::Build;
my ($build, $params);


$params = {
            'license' => 'perl',
            'requires' => {
                            'Test::Most' => '0.34',
                            'B' => '1.42_02',
                            'JSON::Tiny' => '0.50'
                          },
            'dist_abstract' => 'Process::Results - standardized structure for returning results of a process',
            'module_name' => 'Process::Results',
            'dist_version_from' => 'lib/Process/Results.pm',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
