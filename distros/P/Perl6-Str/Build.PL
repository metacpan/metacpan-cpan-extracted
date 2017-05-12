use strict;
use warnings;
use Module::Build;
require 5.008003;

my $build = Module::Build->new(
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Perl6::Str',
    dist_author        => 'Moritz Lenz',
    dist_abstract      => 'Perl 6 - like grapheme level string handling',
    dist_version_from  => 'lib/Perl6/Str.pm',
    requires => {
        'perl'               => '5.8.3',
        'Unicode::Normalize' => 0,
        'Test::More'         => 0,
        'Encode'             => 0,
        'charnames'          => 0,
    },
    recommends         => {},
    sign               => 0,
);
$build->create_build_script;

# vim: sw=4 ts=4 expandtab
