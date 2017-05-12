# Build.PL, (C) Dominique Quatravaux 2007 (See README for license details)

# This script automatically builds a "Build" file in the current
# directory (using a custom-made subclass to Module::Build), which in
# turn builds the Pod-Snippets package.

require 5.006;

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new
    ( module_name         => 'Pod::Snippets',
      license             => 'perl',
      dist_author         => 'Dominique Quatravaux <domq@cpan.org>',
      dist_version_from   => "lib/Pod/Snippets.pm",
      requires => {
                   "Pod::Parser"  => 0,
                  },
      add_to_cleanup      => [ 'Pod-Snippets-*' ],
      create_makefile_pl  => 'passthrough',
);

$builder->create_build_script();

1;

