use Module::Build;
use strict;

Module::Build->new(
    module_name        => 'SVN::Notify::Filter::Markdown',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.2701' },
    build_requires     => {
        'Test::More'    => '0.17',
        'Module::Build' => '0.2701',
    },
    requires           => {
        'SVN::Notify'    => '2.70',
        'Text::Markdown' => '1.000004',
        'HTML::Entities' => 0,
    },
    recommends         => {
        'Test::Pod'      => '1.41',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/SVN-Notify-Filter-Markdown/',
            bugtracker => 'http://github.com/theory/svn-notify-filter-markdown/issues/',
            repository => 'http://github.com/theory/svn-notify-filter-markdown/',
        }
    },
)->create_build_script;
