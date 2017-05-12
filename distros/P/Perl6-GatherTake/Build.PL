use strict;
use warnings;
use Module::Build;
require 5.006001;

my $build = Module::Build->new(
    create_readme       => 1,
    create_makefile_pl  => 'traditional',
    license             => 'perl',
    module_name         => 'Perl6::GatherTake',
    dist_author         => 'Moritz Lenz',
    dist_abstract       => 'Perl 6 like gather { .. take } blocks',
    dist_version        => '0.0.3',
    requires => {
        'perl'              => '5.6.1',
# I don't really know which Coro version is needed, but 1.0 seems like a
# reasonable guess. Might change in future.
        'Coro'              => '1.0', 
        'Scalar::Util'      => 0,
    },
    recommends          => {},
    sign                => 0,
);
$build->create_build_script;

# vim: sw=4 ts=4 expandtab
