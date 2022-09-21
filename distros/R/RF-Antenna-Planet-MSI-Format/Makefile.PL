use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'RF::Antenna::Planet::MSI::Format',
    VERSION_FROM   => 'lib/RF/Antenna/Planet/MSI/Format.pm',
    PREREQ_PM      => {
                       'Scalar::Util' => 0,
                       'Tie::IxHash'  => 0,
                       'Path::Class'  => 0.12, #chomp while you slurp
                      },
    ABSTRACT_FROM  => 'lib/RF/Antenna/Planet/MSI/Format.pm',
    AUTHOR         => 'Michael R. Davis',
    EXE_FILES      => [
                      qw{
                         scripts/perl-RF-Antenna-Planet-MSI-Format-printer.pl
                        }
                      ],
    META_MERGE     => {
                       resources => {
                                     'repository' => {
                                                      'web' => 'https://github.com/mrdvt92/perl-RF-Antenna-Planet-MSI-Format.git',
                                                      'url' => 'git@github.com:mrdvt92/perl-RF-Antenna-Planet-MSI-Format.git',
                                                      'type' => 'git'
                                                     },
                                     'homepage' => 'https://github.com/mrdvt92/perl-RF-Antenna-Planet-MSI-Format',
                                     'bugtracker' => {
                                                      'web' => 'https://github.com/mrdvt92/perl-RF-Antenna-Planet-MSI-Format/issues'
                                                     }
                                           },
                       'meta-spec' => {
                                       'version' => 2
                                      }
                      },
);
