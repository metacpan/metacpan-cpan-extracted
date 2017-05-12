use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Plugin::Filter::ANSIColor',
    license             => 'perl',
    dist_author         => q{"Andrei V. Toutoukine" <"tut@isuct.ru">},
    dist_version_from   => 'lib/Template/Plugin/Filter/ANSIColor.pm',
    build_requires => {
        'Test::Most'	=> 0,
        'Test::Magpie'	=> 0,
    	'Term::ANSIColor'	=> 3.01,
    	'Template'			=> 0,
    	'Term::Terminfo'	=> 0.06, 
    },
    requires => {
    	'Term::ANSIColor'	=> 3.01,
    	'Template'			=> 0,
    	'Term::Terminfo'	=> 0.06, 
    },
    add_to_cleanup      => [ 'Template-Plugin-Filter-ANSIColor-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
