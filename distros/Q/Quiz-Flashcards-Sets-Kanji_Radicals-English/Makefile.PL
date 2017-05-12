use inc::Module::Install;

name     'Quiz-Flashcards-Sets-Kanji_Radicals-English';
all_from 'lib/Quiz/Flashcards/Sets/Kanji_Radicals/English.pm';
author   'Christian Walde <mithaldu@yahoo.de>';
license  'perl';

build_requires 'Test::More';
build_requires 'Quiz::Flashcards';

auto_install;

WriteAll;

