use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SMS::Send::AT::SmsAt',
    license             => 'perl',
    dist_author         => 'Stefan Seifert <stefan.seifert@atikon.com>',
    dist_version_from   => 'lib/SMS/Send/AT/SmsAt.pm',
    requires => {
        'Test::More'  => 0,
        'SMS::Send'   => 0,
        'XML::XPath'  => 0,
        'XML::Writer' => 0,
        'LWP::UserAgent' => 0,
        'Carp'        => 0,
        'version'     => 0,
    },
    add_to_cleanup      => [ 'SMS-Send-AT-SmsAt-*' ],
);

$builder->create_build_script();
