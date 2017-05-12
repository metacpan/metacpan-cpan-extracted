#!/usr/bin/env perl
#  Copyright (C) 2013-2014 Rocky Bernstein <rocky@cpan.org>
#

use strict;
use warnings;
use Module::Build;
use Config;
use File::Basename;
use File::Spec;

my $min_file_homedir_version = '0.81';
my $min_perl_version         = '5.008005';

my $lib = File::Spec->catfile(dirname(__FILE__), 'lib');
unshift @INC, $lib;
## my $release_status = 'testing';
my $release_status = 'stable';
my $builder = Module::Build->new(
    module_name         => 'Term::ReadLine::Perl5',
    add_to_cleanup      => ['Term-ReadLine-Perl5*', 'tmp*', '.history.text',
			    'pod2htm*.tmp'],
    create_makefile_pl  => 'passthrough',
    dist_abstract       => 'Perl5 version of GNU ReadLine.',
    dist_author         => 'Rocky Bernstein <rocky@cpan.org>',
    dist_version_from   => 'lib/Term/ReadLine/Perl5.pm',
    license             => 'perl',
    needs_compiler      => 0,
    release_status      => $release_status,

    meta_merge => {
	resources => {
	    bugtracker  => 'https://github.com/rocky/p5-Term-ReadLine-Perl5/issues',
	    repository  => 'http://github.com/rocky/p5-Term-ReadLine-Perl5'
	}
    },

    recommends => {
	'rlib' => '0.02',
    },

    build_requires => {
        'File::HomeDir'           => $min_file_homedir_version,
	'File::Spec'              => 0,
	'Term::ReadKey'           => '2.3',
	'Term::Cap'               => 0,
    },
    configure_requires => {
	'Module::Build'           => '0.4004',  # Min "test_requires"
	'perl'                    => $min_perl_version,
    },
    test_requires => {
	"Test::More"              => "0.98",
    },
    requires => {
        'perl'                    => $min_perl_version,
        'version'                 => 0,
        'File::HomeDir'           => $min_file_homedir_version,
	'File::Spec'              => 0,
        'Term::ReadKey'           => 2.3,
	# For OO Readline (formerly Caroline)
	"Class::Accessor::Lite"   => '0.05',
	'IO::Handle'              => '0',
	'POSIX'                   => '0',
	'Text::VisualWidth::PP'   => '0',
	'Unicode::EastAsianWidth::Detect' => '0.03',

    },
    sign                => ($ENV{PERL_MB_NOSIGN} ? 0 : 1),
    );

$builder->create_build_script();
