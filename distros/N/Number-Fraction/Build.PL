use Module::Build;
my $build = Module::Build->new(
  module_name => 'Number::Fraction',
  license => 'perl',
  requires => {
    perl     => '5.10.0',
    Carp     => 0,
    overload => 0,
    Moo      => 0,
    MooX::Types::MooseLike::Base => 0,
  },
  build_requires => {
    'Test::More'  => 0,
    'Test::Warn'          => 0,
  },
  build_recommends => {
    'Test::Pod'           => 0,
    'Test::Pod::Coverage' => 0,
  },
  create_makefile_pl => 'traditional',
  meta_merge => {
    'meta-spec' => { version => 2 },
    resources  => {
      repository => {
        type => 'git',
        url  => 'https://github.com/p5-number-fraction/number-fraction.git',
        web  => 'https://github.com/p5-number-fraction/number-fraction',
      },
      bugtracker => {
        web  => 'https://github.com/p5-number-fraction/number-fraction/issues',
      },
    },
  },

);

$build->create_build_script;
