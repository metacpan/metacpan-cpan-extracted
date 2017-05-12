# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Install the Tickit::Widget modules.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-Tickit-Widget';
readme_from 'Widget.pm';
recursive_author_tests('xt');
requires 'Tickit::Widget::Breadcrumb' => 0.003;
requires 'Tickit::Widget::Calendars' => 0.001;
requires 'Tickit::Widget::Choice' => 0.02;
requires 'Tickit::Widget::Decoration' => 0.004;
requires 'Tickit::Widget::FileViewer' => 0.004;
requires 'Tickit::Widget::Figlet' => 0.003;
requires 'Tickit::Widget::FloatBox' => 0.03;
requires 'Tickit::Widget::Layout::Desktop' => 0.009;
requires 'Tickit::Widget::Layout::Relative' => 0.005;
requires 'Tickit::Widget::LogAny' => 0.004;
requires 'Tickit::Widget::Menu' => 0.09;
requires 'Tickit::Widget::Progressbar' => 0.101;
requires 'Tickit::Widget::ScrollBox' => 0.07;
requires 'Tickit::Widget::Scroller' => 0.22;
requires 'Tickit::Widget::SegmentDisplay' => 0.04;
requires 'Tickit::Widget::SparkLine' => 0.105;
requires 'Tickit::Widget::Statusbar' => 0.004;
requires 'Tickit::Widget::Tabbed' => 0.019;
requires 'Tickit::Widget::Table' => 0.214;
requires 'Tickit::Widget::Table::Paged' => 0.004;
requires 'Tickit::Widget::Term' => 0.002;
requires 'Tickit::Widget::Tree' => 0.114;
requires 'Tickit::Widget::VHBox' => 0.001;
requires 'Tickit::Widgets' => 0.22;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Task-Tickit-Widget';
resources 'homepage' => 'https://github.com/tupinek/Task-Tickit-Widget';
resources 'repository' => 'git://github.com/tupinek/Task-Tickit-Widget';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
