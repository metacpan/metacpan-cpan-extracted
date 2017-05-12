################
# Created by: setitesuk
# Created on: 2009-11-06

use strict;
use warnings;
use Module::Build;
use lib qw(. lib);

our $VERSION = 0.27;

my $builder = Module::Build->new(
				 module_name         => 'MooseX::AttributeCloner',
				 dist_author         => q(Andy Brown <setitesuk@gmail.com>),
				 dist_version        => $VERSION,
				 dist_abstract       => q[Role to clone attribute values from one class into another],
				 license             => 'lgpl3',
				 requires            => {
				  'Moose' => 0,
				  'Moose::Role' => 0,
				  'MooseX::Getopt' => 0,
				  'Carp' => 1.04,
				  'English' => 1.02,
				  'Readonly' => '1.03',
				  'Test::More' => 0.74,
          'Test::Exception' => 0,
          'JSON' => 0,
				 },
				 recommends          => {
							},
				 build_requires      => {
							 'Test::More' => '0.8',
               'Test::Exception' => 0,
               'JSON' => 0,
               'MooseX::InsideOut' => 0,
							},
				 build_recommends    => {
							 'Test::Cmd' => '1.05',
							 'Test::File' => '1.28',
							 'Test::Perl::Critic' => '1.116',
							 'Test::Distribution' => 0,
							 'Test::Kwalitee' => 0,
							 'Test::Pod' => 0,
							 'Test::Pod::Coverage' => 1.00,
							 
							},
				 create_makefile_pl  => 'small',
				 configure_requires  => { 'Module::Build' => 0.3603 }
				);

$builder->create_build_script();
