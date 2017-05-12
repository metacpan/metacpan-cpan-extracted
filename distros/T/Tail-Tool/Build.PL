use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Tail::Tool',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Tail/Tool.pm',
    requires          => {
        'perl'                         => 5.006,
        'AnyEvent'                     => 0,
        'AnyEvent::Loop'               => 0,
        'AnyEvent::Impl::Perl'         => 0,
        'File::HomeDir'                => 0,
        'Getopt::Alt'                  => '0.1.1',
        'IO::Prompt'                   => 0,
        'List::Util'                   => 0,
        'List::MoreUtils'              => 0,
        'Moose'                        => 0,
        'Moose::Role'                  => 0,
        'Moose::Util::TypeConstraints' => 0,
        'Path::Tiny'                   => 0,
        'Pod::Usage'                   => 0,
        'Readonly'                     => 0,
        'Scalar::Util'                 => 0,
        'Term::ANSIColor'              => 0,
        'TryCatch'                     => 0,
        'Term::Spinner'                => 0,
        'version'                      => 0,
        'warnings'                     => 0,
        'YAML'                         => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => 0,
        'Test::Output'   => 0,
    },
    recommends => {
        'Linux::Inotify2'    => 0,
        'Test::Spelling'     => 0,
        'Test::Perl::Critic' => 0,
        'Test::Kwalitee'     => 0,
        'Pod::Coverage'      => 0,
    },
    add_to_cleanup     => [ 'Tail-Tool-*' ],
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'git://github.com/ivanwills/Tail-Tool.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tail::Tool',
        },
    },
);

$builder->create_build_script();
