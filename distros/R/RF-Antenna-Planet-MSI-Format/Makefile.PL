use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'RF::Antenna::Planet::MSI::Format',
    VERSION_FROM   => 'lib/RF/Antenna/Planet/MSI/Format.pm',
    PREREQ_PM      => {
                       'Test::Simple'             => 0,    #Test::More
                       'Test::Number::Delta'      => 0,
                       'Scalar::Util'             => 0,    #looks_like_number
                       'Tie::IxHash'              => 0,    #ordered header
                       'Path::Class'              => 0.12, #slurp
                       'RF::Functions'            => 0.04, #dbi_dbd dbd_dbi
                       'File::Temp'               => 0,    #write to tmp file  #optional
                       'Archive::Zip'             => 0,    #read_fromZipMember #optional
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
