use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SMS::Server::Tools',
    license             => 'perl',
    dist_author         => 'Thomas Lenz <tholen@cpan.org>',
    dist_version_from   => 'lib/SMS/Server/Tools.pm',
    requires            => {
        'Test::More'      => 0,
        'Class::Accessor' => 0.31,
        'Log::Log4perl'   => 1,
    },
    build_requires      => {
        'Test::More'      => 0,
        'Class::Accessor' => 0.31,
        'Log::Log4perl'   => 1,
    },
    create_readme       => 1,
    add_to_cleanup      => [ 'SMS-Server-Tools-*', '*~', '.*~' ],
    create_makefile_pl  => 'traditional',
    meta_merge          => {
        resources => {
            repository => 'http://github.com/tholen/sms-server-tools-perl',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Server-Tools',
        }
    },
);

$builder->create_build_script();
