use lib '.';
use strict;
use warnings;

use English;
use inc::Module::Install;

# Check OS.
if ($OSNAME eq "MSWin32") {
	die "OS unsupported\n";
}

# Definition.
abstract 'Class for SysV init service manipulation.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'SysV-Init-Service';
readme_from 'Service.pm';
recursive_author_tests('xt');
requires 'Capture::Tiny' => 0;
requires 'Class::Utils' => 0.05;
requires 'English' => 0;
requires 'Error::Pure' => 0.15;
requires 'File::Spec::Functions' => 0;
requires 'List::MoreUtils' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/SysV-Init-Service/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/SysV-Init-Service';
resources 'repository' => 'git://github.com/michal-josef-spacek/SysV-Init-Service';
test_requires 'File::Object' => 0.07;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.07';

# Run.
WriteAll();
