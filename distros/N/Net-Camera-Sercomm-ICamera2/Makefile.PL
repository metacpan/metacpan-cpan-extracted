use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Net::Camera::Sercomm::ICamera2',
    VERSION_FROM   => 'lib/Net/Camera/Sercomm/ICamera2.pm',
    PREREQ_PM      => {
                       'Package::New'   => 0,
                       'LWP::UserAgent' => 0,
                       'HTTP::Request'  => 0,
                      },
    EXE_FILES    => [
                    qw{
                       scripts/perl-Net-Camera-Sercomm-ICamera2-getSnapshot.pl
                      }
                    ],

    ABSTRACT_FROM  => 'lib/Net/Camera/Sercomm/ICamera2.pm',
    AUTHOR         => 'Michael R. Davis <mrdvt at cpan>',
    LICENSE        => 'mit',
    META_MERGE     => {
        'meta-spec' =>  { version => 2 },
        'resources' =>  {
                          homepage   => 'https://github.com/mrdvt92/perl-Net-Camera-Sercomm-ICamera2',
                          bugtracker => {
                              web  => 'https://github.com/mrdvt92/perl-Net-Camera-Sercomm-ICamera2/issues',
                          },
                          repository => {
                              type => 'git',
                              url  => 'git@github.com:mrdvt92/perl-Net-Camera-Sercomm-ICamera2.git',
                              web  => 'https://github.com/mrdvt92/perl-Net-Camera-Sercomm-ICamera2.git',
                          },
                        },
                      },
);
