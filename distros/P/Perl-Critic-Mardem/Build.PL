#!perl

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.05';

use Module::Build;

Module::Build->VERSION( '0.4004' );

my $builder = Module::Build->new(
    'module_name'        => 'Perl::Critic::Mardem',
    'dist_abstract'      => 'Some Perl::Critic::Policies to search for needed refactoring',
    'license'            => 'Perl_5',
    'dist_author'        => q{Markus Demml <mardem@cpan.com>},
    'dist_version_from'  => 'lib/Perl/Critic/Mardem.pm',
    'release_status'     => 'stable',
    'configure_requires' => { 'Module::Build' => '0.4004', },
    'test_requires'      => {
        'Test::More'              => 0,
        'English'                 => 0,
        'Test::CheckManifest'     => 0,
        'Test2::V0'               => 0,
        'Test2::Tools::Exception' => 0,
        'Cwd'                     => 0,
        'Path::This'              => 0,
        'Test::Pod'               => 0,
        'Test::Pod::Coverage'     => 0,
        'Pod::Coverage'           => 0,
    },
    'requires' => {
        'perl'                        => 5.010,
        'Exporter'                    => 0,
        'Readonly'                    => 0,
        'List::Util'                  => 0,
        'Perl::Critic'                => 0,
        'Perl::Critic::Policy'        => 0,
        'Perl::Critic::Utils'         => 0,
        'Perl::Critic::Utils::McCabe' => 0,
    },
    'recommends' => {

    },
    'add_to_cleanup' => [ 'Perl-Critic-Mardem-*' ],
    'meta_merge'     => {
        'resources' => {
            # 'bugtracker' => 'https://github.com/mardem1/perl-critic-mardem/issues',
            # 'homepage'   => 'https://github.com/mardem1/perl-critic-mardem',
            'repository' => 'git://github.com/mardem1/perl-critic-mardem.git',
        },
    },
);

$builder->create_build_script();

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

Build.PL

=head1 AUTHOR

Markus Demml, mardem@cpan.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2024, Markus Demml

This library is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.
The full text of this license can be found in the LICENSE file included
with this module.

=cut
