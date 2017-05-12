use Module::Build;

my $build = Module::Build->new(
  module_name   => 'Net::Halo::Status',
  license       => 'perl',
  dist_author   => 'Terje Bless <link@cpan.org>',
  dist_abstract => 'Query Halo game server status.',
  requires      => {
    'perl' => '5.6.1',
  },
)->create_build_script;

