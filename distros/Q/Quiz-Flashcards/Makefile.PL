use inc::Module::Install;

name     'Quiz-Flashcards';
all_from 'lib/Quiz/Flashcards.pm';
author   'Christian Walde <mithaldu@yahoo.de>';
license  'perl';

build_requires 'Test::More';
build_requires 'Wx';
build_requires 'Wx::Perl::ListCtrl';
build_requires 'DBI';
build_requires 'Module::Find';
build_requires 'Module::Install::Share';
build_requires 'File::ShareDir';
build_requires 'File::HomeDir';
build_requires 'File::Spec::Functions';
build_requires 'Time::HiRes';

auto_install;

install_share;

WriteAll;

