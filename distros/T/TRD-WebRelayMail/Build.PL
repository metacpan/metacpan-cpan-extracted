use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'TRD::WebRelayMail',
    license             => 'perl',
    dist_author         => 'Takuya Ichikawa <ichi@cpan.org>',
    dist_version_from   => 'lib/TRD/WebRelayMail.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
		'CGI'        => 0,
        'LWP'        => 0,
        'Carp'       => 0,
		'Test::Perl::Critic' => 0,
    },
    add_to_cleanup      => [ 'TRD-WebRelayMail-*' ],
);

$builder->create_build_script();
