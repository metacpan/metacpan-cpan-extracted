use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Plack::App::PubSubHubbub::Subscriber',
    license             => 'perl',
    dist_author         => 'Antoine Imbert <antoine.imbert@gmail.com>',
    dist_version_from   => 'lib/Plack/App/PubSubHubbub/Subscriber.pm',
    dist_abstract       => 'PubSubHubbub subscriber implementation as a Plack App',
    configure_requires => { 'Module::Build' => 0.38 },
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    requires => {
        'perl' => '5.10.0',
        'URI' => 0,
        'LWP' => 0,
        'HTTP::Message' => 0,
        'Plack' => 0,
    },
    meta_add => {
        resource => {
            repository => {
                url => 'git://github.com/ant0ine/Plack-App-PubSubHubbub-Subscriber.git',
                web => 'http://github.com/ant0ine/Plack-App-PubSubHubbub-Subscriber',
                type => 'git',
            }
        }
    },
    add_to_cleanup      => [ 'Plack-App-PubSubHubbub-Subscriber-*' ],
    create_makefile_pl => 'traditional',
    create_readme => 1,
);

$builder->create_build_script();
