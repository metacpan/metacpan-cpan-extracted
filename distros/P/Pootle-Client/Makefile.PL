use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Pootle-Client',
  VERSION_FROM => 'lib/Pootle/Client.pm',
  ABSTRACT     => 'Pootle API Client library',
  AUTHOR       => 'Olli-Antti Kivilahti <olli-antti.kivilahti@jns.fi>',
  LICENSE      => 'Perl 5',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['examples', 't']},
    prereqs        => {runtime => {requires => {perl => '5.22.1'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/KohaSuomi/Pootle-Client/issues'},
      homepage   => 'https://github.com/KohaSuomi/Pootle-Client/',
      repository => {
        type => 'git',
        url  => 'https://github.com/KohaSuomi/Pootle-Client.git',
        web  => 'https://github.com/KohaSuomi/Pootle-Client/',
      },
    },
  },
  PREREQ_PM => {
    'LWP::UserAgent'        => '6.27',
    'JSON::XS'              => '3.04',
    'File::Temp'            => '0.2304',
  },
  EXE_FILES => ['script/pootle-client'],
  test => {TESTS => 't/*.t t/*/*.t'}
);

