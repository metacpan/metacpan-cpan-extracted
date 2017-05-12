use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Amazon::EC2::Metadata',
    license             => 'perl',
    dist_author         => 'Nathan McFarland <nmcfarl@cpan.org>',
    dist_version_from   => 'lib/Net/Amazon/EC2/Metadata.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Net-Amazon-EC2-Metadata-*' ],
);

$builder->create_build_script();
