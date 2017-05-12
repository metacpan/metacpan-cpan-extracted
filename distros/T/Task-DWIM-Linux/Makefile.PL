use inc::Module::Install;
use lib 'lib';
use Task::DWIM::Linux;

name           'Task-DWIM-Linux';
all_from       'lib/Task/DWIM/Linux.pm';

build_requires 'Test::More'                => '0.42';
build_requires 'Perl::Version'             => '1.011';
build_requires 'Config::Tiny'              => '2.20';

requires perl  => 5.008;

my %modules = Task::DWIM::Linux::get_modules();
foreach my $name (keys %modules) {
    requires $name => $modules{$name};
}

repository 'https://github.com/dwimperl/Task-DWIM';

WriteAll;


