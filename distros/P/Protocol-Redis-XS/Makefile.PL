use strict;
use warnings;
use 5.008001;
use ExtUtils::MakeMaker 6.31;
use ExtUtils::Depends;

my $pkg = ExtUtils::Depends->new("Protocol::Redis::XS", "XS::Object::Magic", "Alien::hiredis");

my %WriteMakefile_args = (
  NAME          => 'Protocol::Redis::XS',
  AUTHOR        => 'David Leadbeater <dgl@dgl.cx>',
  LICENSE       => 'perl_5',
  ABSTRACT_FROM => 'lib/Protocol/Redis/XS.pm',
  VERSION_FROM  => 'lib/Protocol/Redis/XS.pm',

  MIN_PERL_VERSION => '5.008001',

  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.31',
    'ExtUtils::Depends' => 0,
    'XS::Object::Magic' => 0,
    'Alien::Base' => '1.65', # ExtUtils::Depends compatibility
    'Alien::hiredis' => '0.003',
  },

  TEST_REQUIRES => {
    'Test::More' => '0.88',
    'Protocol::Redis::Test' => 0,
  },

  PREREQ_PM => {
    'XSLoader' => 0,
    'XS::Object::Magic' => 0,
    'Protocol::Redis' => '1.0011',
    'parent' => 0,
  },

  $pkg->get_makefile_vars,

  META_MERGE => {
    'meta-spec'    => { version => 2 },
    prereqs        => {
      develop      => {
        requires   => {
          'Devel::Gladiator' => 0,
        },
      },
    },
    resources      => {
      repository   => {
        type       => 'git',
        url        => 'https://github.com/dgl/protocol-redis-xs.git',
        web        => 'https://github.com/dgl/protocol-redis-xs',
      },
      bugtracker   => { web => 'https://github.com/dgl/protocol-redis-xs/issues' },
      x_IRC        => 'irc://irc.perl.org/#redis',
    },
    x_contributors => [
      '5c30 <10b39ae0@13os.net>',
      'Dan Book <grinnz@grinnz.com>',
      'Lukas Mai <lukasmai.403@gmail.com>',
      'Mike Magowan <mike@magowan.co.uk>',
      'Sergey Zasenko <d3fin3@gmail.com>',
    ],
  },
);

delete $WriteMakefile_args{META_MERGE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.46') };
delete $WriteMakefile_args{MIN_PERL_VERSION}
  unless eval { ExtUtils::MakeMaker->VERSION('6.48') };
unless (eval { ExtUtils::MakeMaker->VERSION('6.64') }) {
  my $test_requires = delete $WriteMakefile_args{TEST_REQUIRES};
  $WriteMakefile_args{PREREQ_PM}{$_} = $test_requires->{$_} for keys %$test_requires;
}

WriteMakefile(%WriteMakefile_args);
