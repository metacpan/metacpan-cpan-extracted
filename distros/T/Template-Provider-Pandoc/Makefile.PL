use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Template::Provider::Pandoc',
  VERSION_FROM => 'lib/Template/Provider/Pandoc.pm',
  LICENSE      => 'perl_5',

  MIN_PERL_VERSION => '5.10.0',

  PREREQ_PM    => {
    Template => 0,
    Pandoc   => 0,
    Moose    => 0,
    MooseX::NonMoose => 0,
  },

  META_MERGE    => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/davorg-cpan/template-provider-pandoc.git',
        web  => 'https://github.com/davorg-cpan/template-provider-pandoc',
      },
      bugtracker => {
        web  => 'https://github.com/davorg-cpan/template-provider-pandoc/issues',
      },
    },
  }
);
