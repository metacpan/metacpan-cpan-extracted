use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::SMS::TMobile::UK',
    license             => 'perl',
    dist_author         => 'Ben Charlton <benc@cpan.org>',
    dist_version_from   => 'lib/Net/SMS/TMobile/UK.pm',
    requires 	=> {
	'LWP::UserAgent' => 0,
	'HTTP::Request::Common' => 0,
	'Crypt::SSLeay' => 0,

    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Net-SMS-TMobile-UK-*' ],
);

$builder->create_build_script();
