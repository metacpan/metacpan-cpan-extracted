#!/usr/bin/perl -w

use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Sub::NamedParams',
    license            => 'perl',
    dist_author        => 'Curtis "Ovid" Poe <moc.oohay@eop_divo_sitruc>',
    dist_version_from  => 'lib/Sub/NamedParams.pm',
    requires           => {},
    build_requires     => {},
    add_to_cleanup     => ['Sub-NamedParams-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

# does anyone even read this?  Maybe I should include poems about daisies,
# puppies, and blood.  I'm pretty sure I'd find out quickly if they do.
