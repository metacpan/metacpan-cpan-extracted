use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Mojo::UserAgent::UnixSocket',
  ABSTRACT_FROM => 'lib/Mojo/UserAgent/UnixSocket.pm',
  VERSION_FROM => 'lib/Mojo/UserAgent/UnixSocket.pm',
  AUTHOR => 'Ben Tyler',
  LICENSE => 'perl',
  PREREQ_PM => {
    'Mojolicious' => '5.00',
    'IO::Socket::UNIX' => '1.23'
  },
  META_MERGE => {
    resources => {
      license => 'http://dev.perl.org/licenses/',
      homepage => 'https://github.com/kanatohodets/mojo-useragent-unixsocket',
      bugtracker => 'https://github.com/kanatohodets/mojo-useragent-unixsocket/issues',
      repository => 'https://github.com/kanatohodets/mojo-useragent-unixsocket',
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);
