use inc::Module::Install;

name     'Quiz-Flashcards-Audiobanks-Japanese_Words_Radicals';
all_from 'lib/Quiz/Flashcards/Audiobanks/Japanese_Words_Radicals.pm';
author   'Christian Walde <mithaldu@yahoo.de>';
license  'perl';

build_requires 'Test::More';
build_requires 'Quiz::Flashcards';

auto_install;

install_share;

WriteAll;

