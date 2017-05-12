use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SMS::Send::DE::MeinBMW',
    license             => 'perl',
    dist_author         => 'Boris Zentner <bzm@2bz.de>',
    dist_version_from   => 'lib/SMS/Send/DE/MeinBMW.pm',
    requires => {
		 'LWP::UserAgent' => 0,
		 'HTTP::Response' => 0,
		 'HTTP::Request::Common' => 0,
		 'HTTP::Cookies' => 0,
		 'HTML::Form' => 0,
		 Carp => 0,
		 'Test::More' => 0,
		 'SMS::Send::Driver' => 0,
    },
    add_to_cleanup      => [ 'SMS-Send-DE-MeinBMW-*' ],
);

$builder->create_build_script();
