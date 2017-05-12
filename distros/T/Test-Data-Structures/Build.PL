################
# Created by: setitesuk
# Created on: 2009-11-06

use strict;
use warnings;
use Module::Build;
use lib qw(. lib);

our $VERSION = 0.025;

my $builder = Module::Build->new(
				 module_name         => 'Test::Data::Structures',
				 dist_author         => q(Andy Brown <setitesuk@gmail.com>),
				 dist_version        => $VERSION,
				 dist_abstract       => q[Class to add additional helper methods to find out data within data structures],
				 license             => 'lgpl3',
				 requires            => {
				  'Test::Builder' => 0,
				  'Carp' => 1.04,
				  'English' => 1.02,
				  'Readonly' => '1.03',
				 },
				 recommends          => {
							},
				 build_requires      => {
							 'Test::More' => '0.8',
               'Test::Builder' => 0,
               'Test::Exception' => 0,
							},
				 build_recommends    => {
							 'Test::Perl::Critic' => 0,
							 'Test::Distribution' => 0,
							 'Test::Kwalitee' => 0,
							 'Test::Pod' => 0,
							 'Test::Pod::Coverage' => 1.00,
							 
							},
				 create_makefile_pl  => 'small',
				 configure_requires  => { 'Module::Build' => 0.3603 }
				);

$builder->create_build_script();
