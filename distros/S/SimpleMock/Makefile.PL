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
