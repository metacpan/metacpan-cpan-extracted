use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Perl6::Caller',
    license             => 'perl',
    dist_author         => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from   => 'lib/Perl6/Caller.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Perl6-Caller-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
