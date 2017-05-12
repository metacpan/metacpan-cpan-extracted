use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Twitpic',
    license             => 'perl',
    dist_author         => q{Yusuke Sugiyama <ally@blinkingstar.net>},
    dist_version_from   => 'lib/Net/Twitpic.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Net-Twitpic-*' ],
    create_makefile_pl => 'traditional',
    build_requires => {
		'LWP::UserAgent' => 0,
		'HTTP::Request::Common' => 0,
		'JSON' => 0,
		'Net::OAuth' => 0
    },
);

$builder->create_build_script();
