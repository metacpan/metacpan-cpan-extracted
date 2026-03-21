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
    x_authority => 'cpan:TBUSCH',
    keywords => [qw(
      sql query builder composable expression-tree
      select insert update delete truncate
      join cte window-function case union intersect except
      subquery upsert returning distinct
      postgresql mysql sqlite
      dbi bind-parameters injection-protection
    )],
    resources => {
      homepage => 'https://github.com/thomasbusch/perl-SQL-Wizard',
      repository => {
        type => 'git',
        url  => 'https://github.com/thomasbusch/perl-SQL-Wizard.git',
        web  => 'https://github.com/thomasbusch/perl-SQL-Wizard',
      },
      bugtracker => {
        web => 'https://github.com/thomasbusch/perl-SQL-Wizard/issues',
      },
    },
  },
);

sub MY::postamble {
  return <<'MAKE';
readme: lib/SQL/Wizard.pod
	perl tools/pod2readme.pl lib/SQL/Wizard.pod > README.md
MAKE
}
