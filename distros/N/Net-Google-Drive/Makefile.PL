use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Google::Drive',
    LICENSE           => 'perl_5',
    VERSION_FROM      => 'lib/Net/Google/Drive.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    AUTHOR            => 'Pavel Andryushin<vrag867@gmail.com>',
    PREREQ_PM         => {
        'URI'                   => 1.64,
        'LWP::UserAgent'        => 6.27,
        'LWP::Protocol::https'  => 6.06,
        'JSON::XS'              => 3.04,
        'HTTP::Request'         => 6.00,
        'Net::Google::OAuth'    => 0.03,
        'File::Basename'        => 2.85,
        'File::Spec'            => 3.48,
    },
    META_MERGE   => {
          requires  => { perl => '5.008008' },
          resources => {
                license     => 'http://dev.perl.org/licenses/',
                repository  => 'https://github.com/vrag86/perl-net-google-drive',
                bugtracker  => 'https://github.com/vrag86/perl-net-google-drive/issues'
              },
    },
);
