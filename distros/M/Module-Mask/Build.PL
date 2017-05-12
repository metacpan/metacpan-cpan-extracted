use strict;
use warnings;

use Module::Build;

=head1 NAME

Build.PL - Build script builder for Module::Mask

=head1 SYNOPSIS

    perl Build.PL
    ./Build test
    ./Build install

     - or -

    perl Makefile.PL
    make test
    make install

=cut

my $builder = Module::Build->new(
    module_name         => 'Module::Mask',
    license             => 'perl',
    dist_author         => 'Matt Lawrence <mattlaw@cpan.org>',
    add_to_cleanup      => [ 'Module-Mask-*' ],
    create_makefile_pl  => 'small',

    requires => {
        'perl' => '5.8.0',
        'Module::Util' => '1.00',
        'Scalar::Util' => '1.01',
    },
    build_requires => {
        'Test::More' => 0,
    },
    configure_requires => {
        'Module::Build' => '0.40',
    },
    recommends => {
        'Test::Pod' => '1.14',
        'Test::Pod::Coverage' => '1.04',
    },
);

$builder->create_build_script;

__END__

=head1 SEE ALSO

Module::Build, Module::Mask

=head1 AUTHOR

Matt Lawrence E<lt>mattlaw@cpan.orgE<gt>

