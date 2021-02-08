use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::POM::Web',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami AT cpan.org>',
    dist_version_from   => 'lib/Pod/POM/Web.pm',
    requires => {
      'perl'                 => 5.008,
      'parent'               => 0,
      'Alien::GvaScript'     => 1.021000,
      'Encode'               => 0,
      'Encode::Detect'       => 0,
      'Pod::POM'             => 0.25,
      'Pod::POM::View::HTML' => 0,
      'List::Util'           => 0,
      'List::MoreUtils'      => 0,
      'Module::CoreList'     => 0,
      'Module::Metadata'     => 1.000033,
      'Time::HiRes'          => 0,
      'HTTP::Daemon'         => 0,
      'MIME::Types'          => 0,
      'URI'                  => 0,
      'URI::QueryParam'      => 0,
      'Config'               => 0,
      'POSIX'                => 0,
      },
    recommends => {
      'Search::Indexer'           => 0.75,
      'PPI::HTML'                 => 0,
    },
    build_requires => {
      'Test::More'     => 0,
      'HTTP::Request'  => 0,
      'HTTP::Response' => 0,
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
