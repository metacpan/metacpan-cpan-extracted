use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name         => 'String::Ident',
    license             => 'perl',
    requires            => {
        'Text::Unidecode' => 0,
    },
    build_requires => {
        'Test::More' => '0.88',
    },
    configure_requires  => { 'Module::Build' => '0.38' },
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    create_readme       => 1,
    add_to_cleanup      => [ 'String-Ident-*' ],
    meta_merge => {
        resources => {
            repository => 'http://github.com/meon/String-Ident',
            bugtracker => 'http://github.com/meon/String-Ident/issues',
        },
        keywords => [ qw/ string cleanup identifier ascii / ],
    },
);
$build->create_build_script;

