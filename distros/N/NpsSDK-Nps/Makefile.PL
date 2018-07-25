use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'NpsSDK::Nps',
  VERSION          => '1.9',
  AUTHOR           => 'IngenicoNpsLatam',
  LICENSE          => 'MIT',
  MIN_PERL_VERSION => '5.008004',
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'XML::Twig' => 0,
    'XML::Parser' => 0,
    'IO::Socket::SSL' => 0,
    'Digest::MD5' => 0,
    'IO' => 0,
    'SOAP::Lite' => 1.20,
    'Encode' => 0,
    'Log::Log4perl' => 1.49,
    'Data::Structure::Util' => 0.16,
    'Log::Dispatch::Screen' => 0,
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/Ingenico-NPS-Latam/nps-sdk-perl.git',
              web  => 'https://github.com/Ingenico-NPS-Latam/nps-sdk-perl',
          },
      }})
   : ()
  ),
);