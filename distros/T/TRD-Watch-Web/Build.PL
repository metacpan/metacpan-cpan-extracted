use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'TRD::Watch::Web',
    license             => 'perl',
    dist_author         => 'Takuya Ichikawa <ichi@cpan.org>',
    dist_version_from   => 'lib/TRD/Watch/Web.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
		'Test::Perl::Critic' => 0,	
		'Time::HiRes' => 0,
		'TRD::DebugLog' => 0,
    },
    add_to_cleanup      => [ 'TRD-Watch-Web-*' ],
);

$builder->create_build_script();
