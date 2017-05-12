use inc::Module::Install;

name           'Process-YAML';
all_from       'lib/Process/YAML.pm';
requires       'Process'      => '0.10';
requires       'YAML::Syck'   => '0.24';
build_requires 'File::Spec'   => '0.80';
build_requires 'File::Temp'   => 0;
build_requires 'File::Remove' => 0;
build_requires 'Test::More'   => '0.47';

WriteAll();
