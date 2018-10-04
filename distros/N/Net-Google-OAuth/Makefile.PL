use 5.008001;
use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Google::OAuth',
    LICENSE           => 'perl_5',
    VERSION_FROM      => 'lib/Net/Google/OAuth.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    AUTHOR            => 'Pavel Andryushin<vrag867@gmail.com>',
    PREREQ_PM         => {
        'URI'                   => 1.64,
        'LWP::UserAgent'        => 6.27,
        'LWP::Protocol::https'  => 6.06,
        'JSON::XS'              => 3.04,
        'HTTP::Request'         => 6.00,
    },
    META_MERGE   => {
          requires  => { perl => '5.008008' },
          resources => {
                license     => 'http://dev.perl.org/licenses/',
                repository  => 'https://github.com/vrag86/perl-net-google-oauth',
                bugtracker  => 'https://github.com/vrag86/perl-net-google-oauth/issues'
              },
    },
);
