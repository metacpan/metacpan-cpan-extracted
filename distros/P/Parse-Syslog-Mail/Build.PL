use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Parse::Syslog::Mail',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/Parse/Syslog/Mail.pm',
    requires => {
        'perl'          => 5,
        'Carp'          => 0,
        'Parse::Syslog' => 0,
    },
    build_requires => {
        'Test::More'    => 0,
    },
    recommands => {
        'File::Tail'    => 0,
        'Test::Exception' => 0,
        'Test::Warn'    => 0,
    },
    add_to_cleanup      => [ 'Parse-Syslog-Mail-*' ],
);

$builder->create_build_script();
