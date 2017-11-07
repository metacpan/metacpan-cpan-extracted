use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME               => 'Pootle::Client',
  VERSION_FROM       => 'lib/Pootle/Client.pm',
  ABSTRACT           => 'Pootle API Client library',
  AUTHOR             => 'Olli-Antti Kivilahti <olli-antti.kivilahti@jns.fi>',
  LICENSE            => 'Perl_5',
  MIN_PERL_VERSION   => '5.20.0',
  META_MERGE         => {
    dynamic_config     => 0,
    'meta-spec'        => { version   => 2 },
    no_index           => { directory => ['examples', 't'] },
    resources          => {
      bugtracker         => { web => 'https://github.com/KohaSuomi/Pootle-Client/issues' },
      homepage           => 'https://github.com/KohaSuomi/Pootle-Client/',
      repository         => {
        type               => 'git',
        url                => 'https://github.com/KohaSuomi/Pootle-Client.git',
        web                => 'https://github.com/KohaSuomi/Pootle-Client/',
      },
    },
  },
  PREREQ_PM => {
    'Carp::Always'          => '0.13',
    'Exception::Class'      => '1.40',
    'File::Temp'            => '0.2304',
    'JSON::XS'              => '3.01',
    'Log::Log4perl'         => '1.49',
    'LWP::UserAgent'        => '6.15',
    'MIME::Base64'          => '3.15',
    'Params::Validate'      => '1.22',
    'Test::MockModule'      => '0.11',
    'Test::Exception'       => '0.38',
    'Try::Tiny'             => '0.24',
  },
  EXE_FILES          => ['script/pootle-client'],
  test               => { TESTS => 't/*.t t/*/*.t' }
);
