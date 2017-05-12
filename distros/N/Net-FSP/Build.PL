use 5.006;
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::FSP',
    license             => 'perl',
    dist_author         => 'Leon Timmermans <leont@cpan.org>',
    dist_version_from   => 'lib/Net/FSP.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires       => {
        perl            => 5.006,
    },
    recommends     => {
        Socket6         => 0,
    },
    meta_merge => {
        resources       => {
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-FSP',
        },
        keywords        => [ 'FSP', 'File service protocol', 'File transfer' ],
		no_index        => {
			'package' => [ 'Net::FSP::Handle' ],
			namespace => [ 'Net::FSP::Handle' ],
		},
    },
    add_to_cleanup      => [ 'Net-FSP-*' ],
    create_makefile_pl  => 'traditional',
	sign                => 1,
);

$builder->create_build_script();
