use strict;
use warnings;
use Module::Build;

if ( -e 'MANIFEST' ) {
    system( 'pod2text lib/Padre/Plugin/Encode.pm > README' );
}

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::Encode',
    license             => 'perl',
    dist_author         => 'Keedi Kim - 김도형 <keedi@cpan.org>',
    dist_version_from   => 'lib/Padre/Plugin/Encode.pm',
    requires => {
        'Test::More'       => 0,
        'version'          => 0,
        'Encode'           => '2.26',
        'Wx::Perl::Dialog' => '0.04',
        'Padre'            => '0.23',
        },
    add_to_cleanup      => [ 'Padre-Plugin-Encode-*' ],
);

$builder->create_build_script();
