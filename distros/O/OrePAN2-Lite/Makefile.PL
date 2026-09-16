use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => 'OrePAN2::Lite',
  MIN_PERL_VERSION => '5.010',
  AUTHOR           => 'Rob Lauer <rclauer@gmail.com>',
  VERSION_FROM     => 'lib/OrePAN2/Lite.pm',
  ABSTRACT         => 'OrePAN2::Lite',
  LICENSE          => 'perl',
  PL_FILES         =>     {}
,
  EXE_FILES        =>     []
,
  MAN1PODS         =>     {}
,
  PREREQ_PM        => {
      'CPAN::Meta' => '2.131560',
      'Class::Accessor::Fast' => '0.51',
      'File::pushd' => '1.016',
      'HTTP::Tiny' => '0.088',
      'IO::File::AtomicChange' => '0.08',
      'JSON::PP' => '4.16',
      'Parse::LocalDistribution' => '0.20',
      'Path::Tiny' => '0.150',
      'Role::Tiny' => '2.002004',
      'Role::Tiny::With' => '2.002004',
      'autodie' => '2.37'
    },
  BUILD_REQUIRES   => {
      'ExtUtils::MakeMaker' => '6.64',
      'File::ShareDir::Install' => 0
    },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => 0,
    },
  TEST_REQUIRES => {
      'Test::RequiresInternet' => '0'
    },
  META_MERGE =>    {
      'meta-spec'=>{
                       'version'=>2
                     },
      'prereqs'=>{
                     'runtime'=>{
                                    'recommends'=>{
                                                      'IO::Socket::SSL'=>'0'
                                                    }
                                  }
                   },
      'provides'=>{
                      'OrePAN2'=>{
                                     'file'=>'lib/OrePAN2.pm',
                                     'version'=>'2.0.0'
                                   },
                      'OrePAN2::Index'=>{
                                            'file'=>'lib/OrePAN2/Index.pm',
                                            'version'=>'2.0.0'
                                          },
                      'OrePAN2::Indexer'=>{
                                              'file'=>'lib/OrePAN2/Indexer.pm',
                                              'version'=>'2.0.0'
                                            },
                      'OrePAN2::Injector'=>{
                                               'file'=>'lib/OrePAN2/Injector.pm',
                                               'version'=>'2.0.0'
                                             },
                      'OrePAN2::Lite'=>{
                                           'file'=>'lib/OrePAN2/Lite.pm',
                                           'version'=>'2.0.0'
                                         },
                      'OrePAN2::Logger'=>{
                                             'file'=>'lib/OrePAN2/Logger.pm',
                                             'version'=>'2.0.0'
                                           },
                      'OrePAN2::Repository'=>{
                                                 'file'=>'lib/OrePAN2/Repository.pm',
                                                 'version'=>'2.0.0'
                                               },
                      'OrePAN2::Repository::Cache'=>{
                                                        'file'=>'lib/OrePAN2/Repository/Cache.pm',
                                                        'version'=>'2.0.0'
                                                      },
                      'OrePAN2::Role::HasLogger'=>{
                                                      'file'=>'lib/OrePAN2/Role/HasLogger.pm',
                                                      'version'=>'2.0.0'
                                                    }
                    },
      'resources'=>{
                       'bugtracker'=>{
                                         'mailto'=>'rclauer@gmail.com',
                                         'web'=>'https://github.com/rlauer6/OrePAN2-Lite/issues'
                                       },
                       'homepage'=>'https://github.com/rlauer6/OrePAN2-Lite',
                       'repository'=>{
                                         'type'=>'git',
                                         'url'=>'git@github.com:rlauer6/OrePAN2-Lite.git',
                                         'web'=>'https://github.com/rlauer6/OrePAN2-Lite'
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
