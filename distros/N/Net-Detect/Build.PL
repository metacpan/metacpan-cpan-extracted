use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Net::Detect',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Net/Detect.pm',
    requires          => {
        'Test::More' => 0,
        'Net::Ping'  => 2.41,
    },
    add_to_cleanup => ['Net-Detect-*'],
);

$builder->create_build_script();
