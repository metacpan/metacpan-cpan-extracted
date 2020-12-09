use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'Plack::App::DirectoryIndex',
  VERSION_FROM      => 'lib/Plack/App/DirectoryIndex.pm',
  MIN_PERL_VERSION  => '5.10.0',
  PREREQ_PM         => {
    Plack => 0,
  },
  BUILD_REQUIRES    => {
    Test::More    => 0,
  },
  ABSTRACT_FROM     => 'lib/Plack/App/DirectoryIndex.pm',
  AUTHOR            => 'Dave Cross <dave@perlhacks.com>',
  LICENSE           => 'perl',
  META_MERGE        => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
      type => 'git',
      url => 'git://github.com/davorg/plack-app-directoryindex.git',
      web => 'https://github.com/davorg/plack-app-directoryindex',
    },
      bugtracker => {
        "web" => "https://github.com/davorg/plack-app-directoryindex/issues"
      }
    },
  },
);
