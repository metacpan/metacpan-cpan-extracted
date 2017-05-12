
use strict;
use warnings;

use inc::Module::Install;

name          ('Module-Install-AuthorTests');
author        ('Ricardo Signes <rjbs@cpan.org>');
license       ('perl');
all_from      ('lib/Module/Install/AuthorTests.pm');

requires('Module::Install' => 0.000); # minimum unknown

author_tests  ('xt');

WriteAll();
