# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Install the Lego modules.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-Lego';
readme_from 'Lego.pm';
recursive_author_tests('xt');
requires 'Lego::From::PNG' => 0.04;
requires 'Lego::Ldraw' => '0.5.8';
requires 'Lego::Part' => '0.03';
requires 'Lego::Part::Image' => '0.05';
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Task-Lego';
resources 'homepage' => 'https://github.com/tupinek/Task-Lego';
resources 'repository' => 'git://github.com/tupinek/Task-Lego';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
