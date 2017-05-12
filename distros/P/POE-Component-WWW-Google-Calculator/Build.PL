use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::WWW::Google::Calculator',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/WWW/Google/Calculator.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'POE'                     => 0.9999,
        'POE::Filter::Reference'  => 1.2187,
        'POE::Filter::Line'       => 1.1920,
        'POE::Wheel::Run'         => 1.2179,
        'WWW::Google::Calculator' => 0.04,
        'Carp'                    => 1.04,
        'perl'                    => '5.008008',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'POE-Component-WWW-Google-Calculator-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/POE/Component/WWW/Google/Calculator.pm > README');
}
$builder->create_build_script();
