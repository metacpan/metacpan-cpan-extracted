use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::AozoraBunko',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Net/AozoraBunko.pm',
    configure_requires  => {
        'Module::Build' => 0.38
    },
    build_requires      => {
        'Test::More'  => 0.88,
        'LWP::Online' => 0,
        'YAML'        => 0,
    },
    requires => {
        'perl'           => '5.8.8',
        'Carp'           => 0,
        'URI'            => 0,
        'URI::Fetch'     => 0,
        'LWP::UserAgent' => 0,
        'Encode'         => 0,
        'Web::Scraper'   => 0,
        'Getopt::Compact::WithCmd' => 0.13,
        'IO::Uncompress::Unzip' => 0,
        'IO::String' => 0,
    },
    add_to_cleanup      => [ 'Net-AozoraBunko-*' ],
    script_files        => [ 'bin/aozora' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Net-AozoraBunko'
      }
    },
);

$builder->create_build_script();
