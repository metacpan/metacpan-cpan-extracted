use strict;
use warnings;

require 5.008001;

use inc::Module::Install;

name 'Sub-Prototype';
all_from 'lib/Sub/Prototype.pm';

requires 'XSLoader';
requires 'Sub::Exporter';

extra_tests();

WriteAll;
