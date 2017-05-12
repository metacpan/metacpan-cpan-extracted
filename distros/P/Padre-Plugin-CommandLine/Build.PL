use 5.006;
use strict;
use warnings;

use Padre::PluginBuilder ();

my $builder = Padre::PluginBuilder->new(
    module_name         => 'Padre::Plugin::CommandLine',
    license             => 'perl',
    dist_author         => 'Gabor Szabo <szabgab@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/CommandLine.pm',
    requires => {
		'Padre'             => '0.43',
		'Wx::Perl::Dialog'  => '0.03',
    },
    build_requires => {
        'Test::More' => 0,
    },
    configure_requires => {
      'Padre::PluginBuilder' => '0.12',
    },
    add_to_cleanup      => [ 'Padre-Plugin-CommandLine-*' ],
    share_dir => 'share',
    meta_merge     => {
        resources => {
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-CommandLine',
        }
    },
);

$builder->create_build_script();
