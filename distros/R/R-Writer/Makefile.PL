use strict;
use inc::Module::Install;

name('R-Writer');
all_from('lib/R/Writer.pm');
requires('Class::Accessor::Fast');
requires('JSON::XS', '2.01');
requires('Sub::Exporter');

auto_install;
WriteAll;