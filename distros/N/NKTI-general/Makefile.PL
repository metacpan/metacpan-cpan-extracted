use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME             => 'NKTI::general',
  ABSTRACT_FROM    => 'lib/NKTI/general.pm',
  VERSION_FROM     => 'lib/NKTI/general.pm',
  PREREQ_PM        => {
    'Test::More'            => 0,
    'JSON'                  => 0,
    'DBI'                   => 0,
    'Data::Dumper'          => 0,
    'LWP::UserAgent'        => 0,
    'HTTP::Request::Common' => 0,
    'CGI'                   => 0,
    'DateTime'              => 0,
    'HTTP::BrowserDetect'   => 0,
  },
  MIN_PERL_VERSION => '5.010001',
  AUTHOR           => 'Achmad Yusri Afandi <yusrideb@cpan.org>',
  LICENSE          => 'perl_5',
  #Value must be from legacy list of licenses here
  #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);