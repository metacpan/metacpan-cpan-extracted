use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Growl',
    license             => 'perl',
    dist_author         => 'Nathan McFarland <nmcfarl@cpan.org>',
    dist_version_from   => 'lib/Net/Growl.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Net-Growl-*' ],
);

$builder->create_build_script();
