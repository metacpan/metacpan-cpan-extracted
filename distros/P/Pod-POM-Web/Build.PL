use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::POM::Web',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami AT cpan.org>',
    dist_version_from   => 'lib/Pod/POM/Web.pm',
    requires => {
      'perl'                 => 5.010,
      'parent'               => 0,
      'Alien::GvaScript'     => 1.021000,
      'CPAN::Common::Index::Mux::Ordered' => 0,
      'Encode'               => 0,
      'Pod::POM'             => 0.25,
      'Pod::POM::View::HTML' => 0,
      'List::Util'           => 0,
      'List::MoreUtils'      => 0,
      'Module::CoreList'     => 0,
      'Module::Metadata'     => 1.000033,
      'Time::HiRes'          => 0,
      'MIME::Types'          => 0,
      'Path::Tiny'           => 0,
      'URI'                  => 0,
      'URI::QueryParam'      => 0,
      'Config'               => 0,
      'POSIX'                => 0,
      'Plack::Request'       => 0,
      'Plack::Response'      => 0,
      'Plack::Util'          => 0,
      'Search::Indexer'      => 1.0,
      'CPAN::Common::Index'  => 0,
      },
    recommends => {
      'PPI::HTML'                 => 0,
    },
    test_requires => {
      'Test::More'            => 0,
      'Plack::Test'           => 0,
      'HTTP::Request::Common' => 0,
    },
    add_to_cleanup      => [ 'Pod-POM-Web-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Pod-POM-Web',
       }
     },
);
$builder->add_build_element($_) foreach qw/js css gif/; # items in Web/lib
$builder->create_build_script();
