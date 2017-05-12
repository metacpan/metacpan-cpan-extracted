use strict;
use warnings;
use inc::Module::Install;

name 'Object-Array';
author 'Hans Dieter Pearcey <hdp@cpan.org>';
all_from;

build_requires 'Test::More' => 0;

requires 'Scalar::Util'            => 0;
requires 'Sub::Exporter'           => 0;
requires 'Sub::Install'            => 0;
requires 'Module::Pluggable'       => 0;
requires 'List::MoreUtils'         => 0;

auto_install;
WriteAll;
