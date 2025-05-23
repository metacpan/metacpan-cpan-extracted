# autogenerated by /home/rlauer/bin/make-cpan-dist.pl on Thu Apr  3 14:31:35 2025

use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => 'Module::ScanDeps::Static',
  MIN_PERL_VERSION => '5.010',
  AUTHOR           => 'BIGFOOT <bigfoot@cpan.org>',
  VERSION_FROM     => 'lib/Module/ScanDeps/Static/VERSION.pm',
  ABSTRACT         => 'scan modules for dependencies',
  LICENSE          => 'perl',
  PL_FILES         => {},
  EXE_FILES        => ['bin/scandeps-static.pl'],
  PREREQ_PM        => {
    'CLI::Simple'                                 => '0',
    'Class::Accessor::Fast'                       => '0',
    'IO::Scalar'                                  => '0',
    'JSON'                                        => '0',
    'Pod::Find'                                   => '0',
    'Progress::Any'                               => '0',
    'Progress::Any::Output'                       => '0',
    'Progress::Any::Output::TermProgressBarColor' => '0',
    'Readonly'                                    => '0'
  },
  BUILD_REQUIRES => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => 0,
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => 0,
  },
  TEST_REQUIRES => { 'Test::More' => '0' },
  META_MERGE    => {
    'meta-spec' => { 'version' => 2 },
    'provides'  => {
      'Module::ScanDeps::FindRequires' => {
        'file'    => 'lib/Module/ScanDeps/FindRequires.pm',
        'version' => '1.7.6'
      },
      'Module::ScanDeps::Static' => {
        'file'    => 'lib/Module/ScanDeps/Static.pm',
        'version' => '1.7.6'
      },
      'Module::ScanDeps::Static::VERSION' => {
        'file'    => 'lib/Module/ScanDeps/Static/VERSION.pm',
        'version' => '1.7.6'
      }
    },
    'resources' => {
      'bugtracker' => { 'web' => '' },
      'homepage'   => '',
      'repository' => {
        'type' => 'git',
        'web'  => ''
      }
    }
  }

);

package MY;

use File::ShareDir::Install;
use English qw(-no_match_vars);

sub postamble {
  my $self = shift;

  my @ret = File::ShareDir::Install::postamble($self);

  my $postamble = join "\n", @ret;

  if ( -e 'postamble' ) {

    local $RS = undef;

    open my $fh, '<', 'postamble'
      or die "could not open postamble\n";

    $postamble .= <$fh>;

    close $fh;
  }

  return $postamble;
}

1;
