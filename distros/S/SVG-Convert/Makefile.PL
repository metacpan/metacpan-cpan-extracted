use strict;
use warnings;
use inc::Module::Install;

name('SVG-Convert');
author('Toru Yamaguchi <zigorou@cpan.org>');
all_from('lib/SVG/Convert.pm');
license('perl');

requires('Carp::Clan');
requires('Class::Accessor::Fast');
requires('Module::Load');
requires('Module::Pluggable::Fast');
requires('Params::Validate');
requires('Scalar::Util');
requires('XML::LibXML');

use_test_base;

auto_include;
auto_install;

WriteAll;
