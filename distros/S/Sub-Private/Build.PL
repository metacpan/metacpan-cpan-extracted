use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Sub::Private',
    license             => 'perl',
    # dist_author         => 'Peter Makholm <peter@makholm.net>',
    dist_author         => 'Nigel Horne <njh@bandsman.co.uk>',
    dist_version_from   => 'lib/Sub/Private.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::NoWarnings' => 0,
    },
    requires => {
        'Attribute::Handlers'  => 0,
        'namespace::clean'     => 0,
        'B::Hooks::EndOfScope' => 0,
        'Sub::Identify'        => 0,
    },
    add_to_cleanup      => [ 'Sub-Private-*' ],
    meta_merge => {
        resources => {
            # repository => 'http://github.com/pmakholm/sub-private-perl/tree/master',
            repository => 'http://github.com/nigelhorne/sub-private-perl/tree/master',
        }
    },
);

$builder->create_build_script();
