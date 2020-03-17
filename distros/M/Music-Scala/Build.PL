#!perl
use strict;
use warnings;
use Module::Build;
Module::Build->new(
    module_name        => 'Music::Scala',
    dist_author        => 'Jeremy Mates <jmates@cpan.org>',
    dist_version_from  => 'lib/Music/Scala.pm',
    dist_abstract      => 'Scala scale support for Perl',
    license            => 'artistic_2',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    release_status     => 'stable',
    sign               => 1,
    configure_requires => {
        'CPAN::Meta'    => '2.142060',
        'Module::Build' => '0.4004',     # test_requires
    },
    requires => {
        'perl'             => '5.10.0',
        'strict'           => 0,
        'Carp'             => 0,
        'File::Basename'   => 0,
        'Moo'              => 0,
        'namespace::clean' => 0,
        'Scalar::Util'     => 0,
    },
    test_requires => {
        'strict'     => 0,
        'File::Cmp'  => '1.07',
        'Test::More' => '0.88',    # done_testing
        'Test::Most' => 0,
    },
    add_to_cleanup => [ 'Music-Scala-*', 't/*.scl' ],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge =>
      { resources => { repository => 'https://github.com/thrig/Music-Scala' } },
)->create_build_script;
