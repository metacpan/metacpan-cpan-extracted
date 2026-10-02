use strict;
use warnings;

use ExtUtils::MakeMaker;

if ($^O eq "cygwin") {
  die "OS unsupported\n";
}

WriteMakefile1(
  NAME              => 'TUI::Vision',
  AUTHOR            => 'J. Schneider',
  VERSION_FROM      => 'lib/TUI/Vision.pm',
  ABSTRACT          => 'Perl TUI Framework (Turbo Vision 2.0 Port)',
  LICENSE           => 'mit',
  MIN_PERL_VERSION  => '5.014',
  EXE_FILES         => ['bin/overview.pl'],

  CONFIGURE_REQUIRES  => {
    'ExtUtils::MakeMaker' => 6.64,
  },

  PREREQ_PM => {
    'autodie::Scope::Guard' => 0,
    'Carp'                  => 1.01,
    'Class::Struct'         => 0,
    'Devel::StrictMode'     => 0.003,
    'Encode'                => 0,
    'Importer'              => 0.026,
    'Import::Into'          => 1.002005,
    'Module::Loaded'        => 0,
    'Params::Check'         => 0,
    'Scalar::List::Utils'   => 1.36,
    'Termbox::PP'           => '0.6.0',
    'Terminal::WCWidth'     => 0,
    'UNIVERSAL::Object'     => 0.17,
  },

  TEST_REQUIRES => {
    'Test::Exception' => 0.43,
    'Test::More'      => 0.95,
    'Devel::Refcount' => '0.10',
  },

  $^O eq 'MSWin32' ? (
    dist => {
        TARFLAGS => '-cvzf',
        COMPRESS => 'perl -MExtUtils::Command -e test_f',
        POSTOP   => 'perl -MExtUtils::Command -e mv $(DISTVNAME).tar '
        . '$(DISTVNAME).tar$(SUFFIX)'
    },
  ) : (
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },      
  ),
  test  => { TESTS => 't/*.t t/*/*.t' },
  clean => { FILES => 'TUI-Vision-*'  },

  META_MERGE => {
    'meta-spec' => {
      version => 2
    },
    homepage  => 'http://brickpool.de',
    resources => {
      repository  => {
        type => 'git',
        url  => 'https://github.com/brickpool/TUI-Vision.git',
        web  => 'https://github.com/brickpool/TUI-Vision',
      },
      bugtracker  => {
        web => 'https://github.com/brickpool/TUI-Vision/issues'
      },
    },
    provides => {
      'PerlX::Assert::PP' 
        => { file => 'lib/PerlX/Assert/PP.pm', version => '0.04' },
      'TUI::Vision' 
        => { file => 'lib/TUI/Vision.pm', version => '2.0.2' },
      'TUI::App' 
        => { file => 'lib/TUI/App.pm', version => '2.0.2' },
      'TUI::ColorSel' 
        => { file => 'lib/TUI/ColorSel.pm', version => '2.0.2' },
      'TUI::Dialogs'
        => { file => 'lib/TUI/Dialogs.pm', version => '2.0.2' },
      'TUI::Drivers'
        => { file => 'lib/TUI/Drivers.pm', version => '2.0.2' },
      'TUI::Editors'
        => { file => 'lib/TUI/Editors.pm', version => '2.0.2' },
      'TUI::Gadgets'
        => { file => 'lib/TUI/Gadgets.pm', version => '2.0.2' },
      'TUI::Help'
        => { file => 'lib/TUI/Help.pm', version => '2.0.2' },
      'TUI::Memory'
        => { file => 'lib/TUI/Memory.pm', version => '2.0.2' },
      'TUI::MsgBox'
        => { file => 'lib/TUI/MsgBox.pm', version => '2.0.2' },
      'TUI::Objects' 
        => { file => 'lib/TUI/Objects.pm', version => '2.0.2' },
      'TUI::StdDlg'
        => { file => 'lib/TUI/StdDlg.pm', version => '2.0.2' },
      'TUI::TextView'
        => { file => 'lib/TUI/TextView.pm', version => '2.0.2' },
      'TUI::Validate'
        => { file => 'lib/TUI/Validate.pm', version => '2.0.2' },
      'TUI::Views'
        => { file => 'lib/TUI/Views.pm', version => '2.0.2' },
      'TUI::toolkit'
        => { file => 'lib/TUI/toolkit.pm', version => '2.0.2' },
    },
    prereqs => {
      runtime => {
        recommends => {
          'PerlX::Assert' => 0.905,
          'Type::Params'  => 2.000001,
          'Sub::Util'     => '1.40',
        },
      },
    },
  },
);

# Taken from eumm-upgrade by Alexandr Ciornii
sub WriteMakefile1 { # void (%params)
  my %params = @_;
  my $eumm_version = $ExtUtils::MakeMaker::VERSION;
  $eumm_version = eval $eumm_version;

  if ($^O eq 'MSWin32') {
    $params{PREREQ_PM}->{'Win32'}                           = 0.59;
    $params{PREREQ_PM}->{'Win32::API'}                      = 0.84;
    $params{PREREQ_PM}->{'Win32::Console'}                  = 0.10;
    $params{PREREQ_PM}->{'Win32::Console::PatchForRT33513'} = 0.008;
    $params{PREREQ_PM}->{'Win32API::File'}                  = 0.1101;
  }

  if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
    $params{BUILD_REQUIRES} = {
      %{$params{BUILD_REQUIRES} || {}},
      %{$params{TEST_REQUIRES}} 
    };
    delete $params{TEST_REQUIRES};
  }
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM} = {
      %{$params{PREREQ_PM} || {}},
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
