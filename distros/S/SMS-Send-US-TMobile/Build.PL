use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SMS::Send::US::TMobile',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/SMS/Send/US/TMobile.pm',
    requires => {
        'Test::More'        => 0,
        'version'           => 0,
        'Net::SSLeay'       => 0,
        'URI::Escape'       => 0,
        'SMS::Send::Driver' => 0,
    },
    add_to_cleanup      => [ 'SMS-Send-US-TMobile-*' ],
);

$builder->create_build_script();
