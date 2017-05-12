use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Task::Twitter',
    license             => 'perl',
    dist_author         => 'Jonathan Leto <jonathan@leto.net>',
    dist_abstract       => 'Install Twitter-related modules',
    dist_version_from   => 'lib/Task/Twitter.pm',
    build_requires => {
        'Test::More'                => 0,
        'Net::Twitter'              => 0,
        'Net::PingFM'               => 0,
        'Log::Dispatch::Twitter'    => 0,
        'Twitter::TagGrep'          => 0,
        'WWW::ItsABot'              => 0,
    },
    add_to_cleanup      => [ 'Task::Twitter-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
print "Have a great day!\n";
