#!/usr/bin/env perl

use 5.006;
use strict;
use warnings;

use Module::Build;

# Generate README.md along with README
# Testing: ./Build.PL; ./Build distmeta
# (alternatively we could override ACTION_distmeta, but this seems smarter)
my $class = Module::Build->subclass(class => 'My::Module::Build', code => <<'TAF');
use Pod::Readme;
use Pod::Markdown;

sub do_create_readme
{
    my $self = shift;
    $self->SUPER::do_create_readme;
    my $docfile = $self->_main_docfile or return;
    if ($self->delete_filetree('README.md'))
    {
        $self->log_verbose("Removed previous 'README.md'\n")
    }
    $self->log_info("Creating README.md using Pod::Markdown\n");
    my $pod_parser = Pod::Readme->new(
        input_file => $docfile,
        translate_to_file => 'README.md',
        translation_class => 'Pod::Markdown'
    );
    $pod_parser->run();
    $self->_add_to_manifest('MANIFEST', 'README.md');
}
TAF

my $builder = $class->new(
    module_name        => 'Passwd::Keyring::Secret',
    license            => 'Artistic_2_0',

    build_requires => {
        'Module::Build' => '0.19',
        'Test::More' => '0.88',
        'Pod::Readme' => '1.001002',
        'Pod::Markdown' => '2.000',
    },

    configure_requires => {
        'Module::Build' => '0.4004',
    },

    requires => {
        'perl' => '5.006',
        'strict' => 0,
        'warnings' => 0,
        'Carp' => 0,
        'Glib::Object::Introspection' => 0,
    },

    test_requires => {
        'Test::More' => '0.96',
    },

    recommends => {
        'Passwd::Keyring::Auto' => 0,
    },

    pm_files => {
        'Secret.pm' => 'lib/Passwd/Keyring/Secret.pm',
    },

    dynamic_config     => 0,
    add_to_cleanup     => [ 'pm_to_blib', 'Passwd-Keyring-Secret-*' ],
    create_license     => 1,
    create_readme      => 1,
#    create_makefile_pl => 'traditional',

    dist_author        => 'Thomas Uhle <uhle@cpan.org>',
    dist_version_from  => 'Secret.pm',

    meta_add => {
        'meta-spec' => { version => 2 },
        keywords  => [ qw( passwords security secure-storage keyring secret seahorse gnome-keyring ) ],
        resources => {
            homepage   => 'https://search.cpan.org/~uhle/Passwd-Keyring-Secret/',
            repository => {
                type   => 'git',
                url    => 'https://gitlab.com/uhle/Passwd-Keyring-Secret.git',
                web    => 'https://gitlab.com/uhle/Passwd-Keyring-Secret',
            },
            bugtracker => {
                web    => 'https://gitlab.com/uhle/Passwd-Keyring-Secret/-/issues',
            },
            license    => 'https://www.perlfoundation.org/artistic-license-20.html',
        }
    }
);

$builder->dispatch('manifest') unless -e 'MANIFEST';

$builder->create_build_script();
