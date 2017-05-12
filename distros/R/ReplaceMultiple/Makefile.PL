use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'ReplaceMultiple',
  VERSION_FROM => 'lib/ReplaceMultiple.pm',
  EXE_FILES => ['scripts/replace'],
  ABSTRACT => "Replace substrings with given strings",
  AUTHOR => 'Victor Porton <porton@narod.ru>',
  LICENSE => "perl_5",
  PREREQ_PM => {
    "File::Slurp" => 0,
    "Text::CSV" => 0,
  },
  TEST_REQUIRES => {
    "Test::More" => 0,
  }
);