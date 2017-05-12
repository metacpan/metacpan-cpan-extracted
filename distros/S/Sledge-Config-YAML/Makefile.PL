use strict;
use warnings;
use inc::Module::Install;

name("Sledge-Config-YAML");
all_from("lib/Sledge/Config/YAML.pm");

requires('YAML::Syck' => 1.07);
requires('File::Slurp');
build_requires('Test::More' => 0.32);

use_test_base;
auto_include;
auto_install;

WriteAll;
