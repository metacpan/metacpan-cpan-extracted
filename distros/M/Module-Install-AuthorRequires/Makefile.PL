use strict;
use warnings;
use inc::Module::Install;

name 'Module-Install-AuthorRequires';
all_from 'lib/Module/Install/AuthorRequires.pm';
license 'perl';

requires 'Module::Install';

WriteAll;
