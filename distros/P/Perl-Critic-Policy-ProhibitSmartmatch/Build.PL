
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    license       => 'perl',
    name          => 'Perl-Critic-Policy-ProhibitSmartmatch',
    module_name   => 'Perl::Critic::Policy::ProhibitSmartmatch',
    dist_abstract => <<'ABSTRACT',
Perl::Critic policies which help to avoid both
explicit and implicit smartmatching
ABSTRACT
    test_requires => {
        'Perl::Critic::TestUtils' => 0,
        'Test::More'              => 0,
    },
    requires => {
        'Perl::Critic::Policy' => 0,
        'Perl::Critic::Utils'  => 0,
        'Readonly'             => 0,
    },
);

$build->create_build_script;
