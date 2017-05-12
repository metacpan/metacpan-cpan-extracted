#!/usr/bin/env perl
#  Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Module::Build;
use Config;
use File::Basename;
use File::Spec;

my $dirname = dirname(__FILE__);
do File::Spec->catfile(($dirname, qw(lib Perl Syntax.pm)));

my $release_status = ($Perl::Syntax::VERSION =~ /_/) ? 'testing' : 'stable';

my $builder = Module::Build->new( 
    module_name         => 'Perl::Syntax',
    create_makefile_pl  => 'passthrough',
    dist_abstract       => 
    'Module to syntax check a Perl program file or exec string.',
    dist_author         => 'Rocky Bernstein <rocky@cpan.org>',
    dist_version_from   => 'lib/Perl/Syntax.pm',
    license             => 'gpl',
    needs_compiler      => 0,
    release_status      => $release_status,

    meta_merge => {
	resources => {
	    bugtracker  => 'https://github.com/rocky/Perl-Syntax/issues',
	    repository  => 'http://github.com/rocky/Perl-Syntax'
	}
    },    

    configure_requires  => { 
	'Module::Build' => '0.32',
			      
    },
    build_requires => {
        # 'String::Diff'        => 0,
    },
    test_requires => {
        'Test::More'                        => '0.81',
    },
    requires => {
	'perl'                              => '5.008008',
        'rlib'                              => '0.02',
        'version'                           => 0,
    },
    sign                => ($ENV{PERL_MB_NOSIGN} ? 0 : 1),
    );

$builder->create_build_script();
