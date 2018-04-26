use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %WriteMakefileArgs = (
  NAME => 'Safe::Isa',
  VERSION_FROM => 'lib/Safe/Isa.pm',

  META_MERGE => {
      'meta-spec' => { version => 2 },
      dynamic_config => 0,
      resources => {
        # GitHub mirrors from Shadowcat. We list it so we can get pull requests.
        # The canonical repo is:
        # r/o: git://git.shadowcat.co.uk/p5sagit/Safe-Isa.git
        # r/w: p5sagit@git.shadowcat.co.uk:Safe-Isa.git
        # web: http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/Safe-Isa.git
        repository => {
          url => 'https://github.com/p5sagit/Safe-Isa.git',
          web => 'https://github.com/p5sagit/Safe-Isa',
          type => 'git',
        },
        bugtracker => {
            mailto => 'bug-Safe-Isa@rt.cpan.org',
            web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Safe-Isa',
        },
      },
      x_contributors => [ # manually added, from git shortlog -e -s -n
        'Karen Etheridge <ether@cpan.org>',
        'Matt S Trout <mst@shadowcat.co.uk>',
        'Graham Knop <haarg@haarg.org>',
        'David Steinbrunner <dsteinbrunner@pobox.com>',
      ],
  },

  META_ADD => {
    'meta-spec' => { version => 2 },
    prereqs => {
      configure => {
        requires => {
          'ExtUtils::MakeMaker' => '0',
        },
      },
      runtime => {
        requires => {
          'Exporter' => '5.57',
          'Scalar::Util' => 0,
          perl => '5.006',
        },
      },
      test => {
        requires => {
          'Test::More' => '0',
        },
      },
    },
  },
);

my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
           or exists $WriteMakefileArgs{$key};
  my $r = $WriteMakefileArgs{$key} = {
    %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
    %{delete $WriteMakefileArgs{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

# dynamic prereqs get added here.

$WriteMakefileArgs{MIN_PERL_VERSION} = delete $WriteMakefileArgs{PREREQ_PM}{perl} || 0;

die 'attention developer: you need to do a sane meta merge here!'
  if keys %{$WriteMakefileArgs{BUILD_REQUIRES}};

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

delete $WriteMakefileArgs{MIN_PERL_VERSION}
  if $eumm_version < 6.48;

delete @WriteMakefileArgs{qw(META_ADD META_MERGE)}
  if $eumm_version < 6.46;

delete $WriteMakefileArgs{LICENSE}
  if $eumm_version < 6.31;

WriteMakefile(%WriteMakefileArgs);
