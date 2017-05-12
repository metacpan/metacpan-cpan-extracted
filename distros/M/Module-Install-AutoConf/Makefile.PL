
use strict;
use warnings;

use inc::Module::Install;

name          ('Module-Install-AutoConf');
author        ('G. Allen Morris III <gam@cpan.org>');
license       ('perl');
all_from      ('lib/Module/Install/AutoConf.pm');

requires('Module::Install' => 0.000); # minimum unknown

author_tests('xt');

WriteAll();
