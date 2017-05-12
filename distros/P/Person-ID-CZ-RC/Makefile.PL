# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Perl class for Czech RC identification.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Person-ID-CZ-RC';
readme_from 'RC.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'DateTime' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0.11;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Person-ID-CZ-RC';
resources 'homepage' => 'https://github.com/tupinek/Person-ID-CZ-RC';
resources 'repository' => 'git://github.com/tupinek/Person-ID-CZ-RC';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
