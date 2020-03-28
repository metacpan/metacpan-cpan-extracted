# Build.PL
# Use to build the package Photonic
our $VERSION = '0.014';

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 1916 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=cut


use strict;
use warnings;
use PDL::Core::Dev;
use ExtUtils::F77 1.23;
use Module::Build::Pluggable::PDL;
use Module::Build::Pluggable::Fortran 0.27;
use Module::Build::Pluggable ('PDL', 'Fortran');

my $builder = Module::Build::Pluggable->new(
    module_name=> 'Photonic',
    dist_name  => 'Photonic',
    dist_author=> [
	'W. Luis Mochan <mochan@fis.unam.mx>',
	'Guillermo Ortiz <gortiz@exa.unne.edu.ar>',
	'Bernardo S. Mendoza <bms@cio.mx>',
	'Jose Samuel Perez-Huerta <jsperez@fisica.uaz.edu.mx>',
	'Lucila Juarez Reyes <lucilajuarezreyes@gmail.com>',
	'Merlyn Jaqueline Juarez-Gutierrez <merlynj@icf.unam.mx>'
	],
    dist_version_from => 'lib/Photonic.pm',
    license    => 'perl',
    release_status => 'stable', #stable, testing or unstable
    f_source   => [ 'fortran' ],
    requires   => {
	'Inline'                         => '0',
	'Carp'                           => '0',
	'Cwd'                            => '0',
	'DynaLoader'                     => '0',
	'English'                        => '0',
	'ExtUtils::F77'                  => '1.23',
	'IO::File'                       => '0',
	'List::Util'                     => '0',
	'List::MoreUtils'                => '0',
	'Machine::Epsilon'               => '0',
	'Moose'                          => '0',
	'Moose::Role'                    => '0',
	'Moose::Util::TypeConstraints'   => '0',
	'MooseX::StrictConstructor'      => '0',
	'perl'                           => '5.10.0',
	'PDL'                            => '0',
	'PDL::Complex'                   => '2.009',
	'PDL::Constants'                 => '0',
	'PDL::Core'                      => '0',
	'PDL::Core::Dev'                 => '0',
	'PDL::Exporter'                  => '0',
	'PDL::FFTW3'                     => '0',
	'PDL::IO::Pic'                   => '0',
	'PDL::IO::Storable'              => '0',
	'PDL::Lite'                      => '0',
	'PDL::MatrixOps'                 => '0',
	'PDL::NiceSlice'                 => '0',
	'Storable'                       => '0',
    },
    test_requires => {
	'Test::More'                  => '0',
	    'Pod::Coverage::TrustPod' => '0',
	    'Test::Pod'           => '0',
	    'Test::Pod::Coverage'  => '1.08',
    },
    configure_requires => {
	'File::Basename'                     => '0',
	'File::Copy'                         => '0',
	'File::Spec'                         => '0',
	'Module::Build'                      => '0.4224',
	'Module::Build::Pluggable'           => '0.10',
	'Module::Build::Pluggable::Fortran'  => '0.27',
	'Module::Build::Pluggable::PDL'      => '0.23',
	'ExtUtils::F77'                      => '1.23',
	'ExtUtils::CBuilder'                 => '0',
	'File::Copy'                         => '0',
    },
    add_to_cleanup  => [ 'Photonic-*', '.xs' ],
    create_makefile_pl => 'small',
    meta_merge     => {
        resources => {
            repository  => 'https://github.com/wlmb/Photonic',
        }
    },
    );
$builder->create_build_script();
