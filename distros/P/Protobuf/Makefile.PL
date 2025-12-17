
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Protobuf',
    VERSION_FROM      => 'lib/Protobuf.pm',
    ABSTRACT_FROM     => 'lib/Protobuf.pm',
    AUTHOR            => 'C.J. Collier <cjac@colliertech.org>',
    LICENSE           => 'apache_2_0',
    MIN_PERL_VERSION  => '5.006',
    PREREQ_PM         => {
      'namespace::autoclean' => 0,
      'Moo'                  => 0,
      'Type::Tiny'           => 0,
      'Types::Standard'      => 0,
    },
    TEST_REQUIRES => {
      'Test::More'          => 0,
      'Test::MockModule'    => 0,
      'File::Spec'          => 0,
      'Path::Tiny'          => 0,
      'Test::Valgrind'      => 0,
      'Test::Perl::Critic'  => 0,
      'Test::Pod'           => 1.22,
      'Test::Pod::Coverage' => 1.08,
      'File::Find'          => 0,
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/protocolbuffers/protobuf.git',
                web  => 'https://github.com/protocolbuffers/protobuf',
            },
            bugtracker => {
                web => 'https://github.com/protocolbuffers/protobuf/issues',
            },
        },
        x_copyright => {
            holder => 'Google LLC and contributors',
            year   => 2025,
        },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Protobuf-* blib', },
    },
);
