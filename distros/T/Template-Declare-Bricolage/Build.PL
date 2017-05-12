use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'Template::Declare::Bricolage',
    license            => 'perl',
    configure_requires => {
        'Module::Build' => '0.2701',
    },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
        'Test::XML'     => 0,
    },
    requires           => {
        'Template::Declare' => 0,
    },
    recommends         => {
        'Test::Pod'           => '1.20',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge         => {
        resources => {
            homepage    => 'http://search.cpan.org/dist/Template-Declare-Bricolage/',
            bugtracker  => 'http://github.com/theory/template-declare-bricolage/issues/',
            repository  => 'http://github.com/theory/template-declare-bricolage/tree/',
        }
    },
)->create_build_script;
