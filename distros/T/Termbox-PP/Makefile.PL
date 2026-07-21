use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile1(
  NAME              => 'Termbox::PP',
  VERSION_FROM      => 'lib/Termbox/PP.pm',
  ABSTRACT          => 'Perl port of the termbox2 terminal library',
  MIN_PERL_VERSION  => '5.010',
  AUTHOR            => 'J. Schneider',
  LICENSE           => 'mit',
  EXE_FILES         => ['bin/build_wcwidth_tables.pl'],

  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 6.64,
  },

  PREREQ_PM => {
  },

  TEST_REQUIRES => {
    'Test::More' => 1.302188,
  },

  META_MERGE => {
    no_index => {
      package => ['Termbox'],
    },
    'meta-spec' => { 
      version => 2 
    },
    homepage  => 'http://brickpool.de',
    resources => {
      repository  => {
        type => 'git',
        url  => 'https://github.com/brickpool/Termbox.git',
        web  => 'https://github.com/brickpool/Termbox',
      },
      bugtracker  => { 
        web => 'https://github.com/brickpool/Termbox/issues',
      },
    },
    prereqs => {
      runtime => {
        requires => {    # v5.10 builtin modules
#          'bytes'           => 0,
          'Carp'            => 0,
          'constant'        => 0,
#          'Config'          => 0,
#          'Errno'           => 0,
          'Exporter'        => 0,
#          'Fcntl'           => 0,
          'IO::File'        => 0,
          'Params::Check'   => 0,
          'Scalar::Util'    => 0,
#          'strict'          => 0,
#          'POSIX'           => 0,
#          'warnings'        => 0,
#          'Unicode::UCD'    => 0,
#          'utf8'            => 0,
#          'vars'            => 0,
        },
        recommends => {
          'Getopt::Long'                    => 0,
          'Encode'                          => 0,
          'lib'                             => 0,
          'List::Util'                      => 0,
          'Pod::Usage'                      => 0,
          'Time::HiRes'                     => 0,
          'Unicode::EastAsianWidth::Detect' => 0,
        },
      },
      test => {
        requires => {    # v5.10 builtin modules
          'Data::Dumper' => 0,
          'File::Temp'   => 0,
        },
      },
    },
  },

  dist => {
    TARFLAGS => '-cvzf',
    COMPRESS => 'perl -MExtUtils::Command -e test_f',
    POSTOP   => 'perl -MExtUtils::Command -e mv $(DISTVNAME).tar $(DISTVNAME).tar$(SUFFIX)'
  },
  test => { TESTS => 't/*.t t/*/*.t' },
);

# Cribbed from eumm-upgrade by Alexandr Ciornii
sub WriteMakefile1 { # void (%params)
  my %params = @_;
  my $eumm_version = $ExtUtils::MakeMaker::VERSION;
  $eumm_version = eval $eumm_version;

  if ($^O eq 'MSWin32') {
    $params{PREREQ_PM}->{'Win32::Console'}  = 0.10;
    $params{PREREQ_PM}->{'Win32::API'}      = 0.75;
    $params{PREREQ_PM}->{'Win32API::File'}  = 0.1201;
    $params{PREREQ_PM}->{'Win32::IPC'}      = 1.11;
  }

  if ($params{TEST_REQUIRES} and $eumm_version < 6.6303) {
    $params{BUILD_REQUIRES} = {
      %{$params{BUILD_REQUIRES} || {}} , 
      %{$params{TEST_REQUIRES}}
    };
    delete $params{TEST_REQUIRES};
  }
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM} = {
      %{$params{PREREQ_PM} || {}} , 
      %{$params{BUILD_REQUIRES}}
    };
    delete $params{BUILD_REQUIRES};
  }

  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;
  delete $params{AUTHOR} if $] < 5.005;
  delete $params{ABSTRACT_FROM} if $] < 5.005;
  delete $params{BINARY_LOCATION} if $] < 5.005;

  WriteMakefile(%params);
}
