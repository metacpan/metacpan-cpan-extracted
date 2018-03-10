use Module::Build;
my $build = Module::Build->new(
  module_name => 'Number::Fraction',
  license => 'perl',
  requires => {
    perl          => '5.6.0',
    Carp                  => 0,
    overload              => 0,
                Moose                 => 0,
  },
  build_requires => {
    'Test::More'        => 0,
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
    },
  },

);

$build->create_build_script;
