use inc::Module::Install;

name     'Term-Pulse';
all_from 'lib/Term/Pulse.pm';
author   q{Alec Chen <alec@cpan.org>};
license  'perl';

build_requires 'Time::HiRes';
build_requires 'Exporter';

test_requires  'Test::More';

homepage   'http://search.cpan.org/dist/Term-Pulse/';
repository 'http://github.com/alecchen/term-pulse';

auto_install;

WriteAll;

