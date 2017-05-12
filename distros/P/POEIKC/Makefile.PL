print "\n", '-'x78, "\n\n";

use inc::Module::Install;
name 'POEIKC';
all_from 'lib/POEIKC.pm';

requires 'Cwd';
requires('Class::Accessor::Fast');
requires('Class::Inspector');
requires('UNIVERSAL::require');
requires('Getopt::Long');
requires('POE');
requires('POE::Sugar::Args');
requires('POE::Component::IKC::Server');
requires('POE::Component::IKC::ClientLite');
requires('Proc::Daemon');
requires('Pod::Usage');
requires('Best');
requires('YAML');
requires 'Proc::ProcessTable';
requires('Proc::Killall');
requires('Term::ReadLine');
requires('Text::ParseWords');

build_requires 'Test::More';
build_requires 'Test::Base';

features(
#    'POD Testing' => [
#        -default => 0,
#        recommends('Test::Pod'),
#        recommends('Test::Pod::Coverage'),
#    ],
    'Better POE::Loop' => [
        -default => 0,
        recommends('POE::Loop::IO_Poll'),
    ],
    'POE::API::Peek' => [
        -default => 0,
        recommends('POE::API::Peek'),
    ],
    'Better Term' => [
        -default => 0,
        recommends('Term::ReadLine::Gnu'),
    ],
    'Date::Calc' => [
        -default => 0,
        recommends('Date::Calc'),
    ],
);

install_script('bin/poeikcd');
install_script('bin/poikc');

use_test_base;
auto_include;
auto_install;

WriteAll;

print "\n", '-'x78, "\n\n";
