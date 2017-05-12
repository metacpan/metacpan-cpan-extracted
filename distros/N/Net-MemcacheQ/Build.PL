#########
# Author:        rmp
# Last Modified: $Date$
# Id:            $Id$
# Source:        $Source$
# $HeadURL$
#
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
				 module_name         => 'Net-MemcacheQ',
				 dist_author         => 'Roger M Pettett <rmp@psyphi.net>',
				 dist_version_from   => 'lib/Net/MemcacheQ.pm',
				 dist_abstract       => q[Basic socket abstraction for memcacheq],
				 license             => 'perl',
				 requires            => {
							 'base'                        => '2.13',
							 'Carp'                        => '1.08',
							 'IO::Socket::INET'            => '1.31',
							 'Readonly'                    => '1.03',
							 'strict'                      => '1.03',
							 'warnings'                    => '1.05_01',
							},
				 recommends          => {
							},
				 build_requires      => {
							 'Test::Distribution'      => '2.00',
							 'Test::More'              => '0.8',
							 'Test::Perl::Critic'      => '1.01',
							 'Test::Trap'              => '0',
							 'Time::HiRes'             => '1.9719',
							 'File::Path'              => '2.07_03',
							},
				 build_recommends    => {
							},
				 create_makefile_pl  => 'passthrough',
#				 script_files        => qw(),
				 sign                => 1,
				);

$builder->create_build_script();
