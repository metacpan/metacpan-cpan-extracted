use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Nagios::Scrape',
    license             => 'perl',
    dist_author         => q{Joe Topjian <joe@terrarum.net>},
    dist_version_from   => 'lib/Nagios/Scrape.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    add_to_cleanup      => [ 'Nagios-Scrape-*' ],
    create_makefile_pl => 'traditional',
    requires => { 
        'CGI' => 0,
        'LWP::UserAgent' => 0,
        'Error' => 0,
    }
);

$builder->create_build_script();
