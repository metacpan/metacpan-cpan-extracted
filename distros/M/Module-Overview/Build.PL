use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Module-Overview',
    license           => 'perl',
    dist_author       => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from => 'lib/Module/Overview.pm',
    
    build_requires => {
        'Test::More'        => 0,
        'Test::Differences' => 0,
    },
    requires => {
        'Class::Accessor::Fast' => 0,
        'Class::Sniff'          => 0,
        'Text::SimpleTable'     => 0,
        'Module::ExtractUse'    => 0,
        'Graph::Easy'           => 0,
        'Carp'                  => 0,
    },
    script_files => [
    	'script/plmo'
    ],
    add_to_cleanup => [ 'Module-Overview-*' ],
    create_readme  => 1,
    sign           => 1,
    meta_merge => {
        resources => {
            repository => 'http://github.com/jozef/Module-Overview',
            bugtracker => 'http://github.com/jozef/Module-Overview/issues',
        },
        keywords => [ qw/ module methods dump overview / ],
    },
);

$builder->create_build_script();
