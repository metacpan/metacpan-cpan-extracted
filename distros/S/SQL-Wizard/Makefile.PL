use ExtUtils::MakeMaker;

my $version = MM->parse_version('lib/SQL/Wizard.pm');

WriteMakefile(
  NAME          => 'SQL::Wizard',
  VERSION_FROM  => 'lib/SQL/Wizard.pm',
  ABSTRACT_FROM => 'lib/SQL/Wizard.pod',
  AUTHOR        => 'Thomas Busch <tbusch@cpan.org>',
  LICENSE       => 'MIT',
  MIN_PERL_VERSION => '5.10.0',
  PREREQ_PM     => {},
  TEST_REQUIRES => {
    'Test::More' => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    provides => {
      'SQL::Wizard' => {
        file    => 'lib/SQL/Wizard.pm',
        version => $version,
      },
    },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/thomasbusch/perl-SQL-Wizard.git',
        web  => 'https://github.com/thomasbusch/perl-SQL-Wizard',
      },
    },
  },
);
