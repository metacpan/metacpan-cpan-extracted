use ExtUtils::MakeMaker;

WriteMakefile(

  NAME            => 'Net::Tools',
  VERSION_FROM    => 'lib/Net/Tools.pm',
  LICENSE         => 'gpl_2',

  # the test suite uses .pl instead of the default .t
  test            => { TESTS => 't/*.pl' },

  TEST_REQUIRES   => {
    'Test::More'                       => 0,
    },

  PREREQ_PM       => {

    # Net::Tools::Socket::Protocols
    'Data::Tools'                      => '1.60',

    },

  META_MERGE      => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/cade-vs/perl-net-tools.git',
        web  => 'https://github.com/cade-vs/perl-net-tools',
      },
    },
  },
);
