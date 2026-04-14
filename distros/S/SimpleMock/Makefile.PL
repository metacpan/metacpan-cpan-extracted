use ExtUtils::MakeMaker;

my %test_requires = (
    'Test::Most'       => 0,
    'DBI'              => 0,
    'LWP::UserAgent'   => 0,
    'HTTP::Status'     => 0,
    'Path::Tiny'       => 0,
    'URI'              => 0,
);

# TEST_REQUIRES was added in EUMM 6.64; fall back to PREREQ_PM on older versions
my $eumm_version = eval $ExtUtils::MakeMaker::VERSION;
my %test_key = $eumm_version >= 6.64
    ? ( TEST_REQUIRES => \%test_requires )
    : ( PREREQ_PM     => \%test_requires );   # merged below

WriteMakefile(
  NAME         => 'SimpleMock',
  VERSION_FROM => 'lib/SimpleMock.pm',
  ABSTRACT     => 'Generic mocking framework for Perl modules',
  AUTHOR       => 'Clive Holloway <clive.holloway@gmail.com>',
  LICENSE      => 'perl',
  MIN_PERL_VERSION => '5.012',
  test         => { TESTS => 't/*.t t/unit_tests/*.t t/unit_tests/*/*.t t/unit_tests/*/*/*.t' },
  PREREQ_PM    => {
    'Carp'             => 0,
    'Data::Dumper'     => 0,
    'Digest::SHA'      => 0,
    'Exporter'         => 0,
    'Hash::Merge'      => 0,
    'Scalar::Util'     => 0,
    'Storable'         => '2.34',
    %{ $test_key{PREREQ_PM} || {} },
  },
  %test_key,
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources   => {
      repository => {
        type => 'git',
        url  => 'https://github.com/cliveholloway/perl_simplemock.git',
        web  => 'https://github.com/cliveholloway/perl_simplemock',
      },
    },
    no_index => {
      directory => [ 't', 'cover_db' ],
    },
    provides => {
      'SimpleMock' => {
        file    => 'lib/SimpleMock.pm',
        version => '0.03',
      },
      'SimpleMock::ScopeGuard' => {
        file    => 'lib/SimpleMock/ScopeGuard.pm',
        version => '0.03',
      },
      'SimpleMock::Util' => {
        file    => 'lib/SimpleMock/Util.pm',
        version => '0.03',
      },
      'SimpleMock::Model::DBI' => {
        file    => 'lib/SimpleMock/Model/DBI.pm',
        version => '0.03',
      },
      'SimpleMock::Model::LWP_UA' => {
        file    => 'lib/SimpleMock/Model/LWP_UA.pm',
        version => '0.03',
      },
      'SimpleMock::Model::PATH_TINY' => {
        file    => 'lib/SimpleMock/Model/PATH_TINY.pm',
        version => '0.03',
      },
      'SimpleMock::Model::SUBS' => {
        file    => 'lib/SimpleMock/Model/SUBS.pm',
        version => '0.03',
      },
      'SimpleMock::Mocks::DBI' => {
        file    => 'lib/SimpleMock/Mocks/DBI.pm',
        version => '0.03',
      },
      'SimpleMock::Mocks::LWP::UserAgent' => {
        file    => 'lib/SimpleMock/Mocks/LWP/UserAgent.pm',
        version => '0.03',
      },
      'SimpleMock::Mocks::Path::Tiny' => {
        file    => 'lib/SimpleMock/Mocks/Path/Tiny.pm',
        version => '0.03',
      },
      'DBD::SimpleMock' => {
        file    => 'lib/DBD/SimpleMock.pm',
        version => '0.03',
      },
    },
    prereqs => {
      runtime => {
        recommends => {
          'DBI'            => 0,
          'LWP::UserAgent' => 0,
          'HTTP::Status'   => 0,
          'Path::Tiny'     => 0,
          'URI'            => 0,
        },
      },
    },
  },
);
