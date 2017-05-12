use inc::Module::Install;

name           'Mirror-YAML';
all_from       'lib/Mirror/YAML.pm';
requires       'Params::Util' => '0.10';
requires       'YAML::Tiny'   => '1.03';
requires       'URI'          => '1.28';
requires       'Time::HiRes'  => 0;
requires       'Time::Local'  => '1.13';
requires       'LWP::Simple'  => 0;
build_requires 'Test::More'   => '0.42';
build_requires 'LWP::Online'  => '0.03';

WriteAll;
