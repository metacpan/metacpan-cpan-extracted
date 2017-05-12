use strict;
use warnings;

=head1 NAME

Build.PL - Build script generator for Module::Util

=head1 SYNOPSIS

    perl Build.PL
    ./Build test
    ./Build install

or 

    perl Makefile.PL
    make test
    make install

=head1 ADDITIONAL TESTS

A very lengthy test script is provided in addition to the normal test suite. It
checks the is_valid_module_name function against every module name in CPAN. It
is not necessary for normal use of the module, but might come in handy for
anyone who wants to make changes to the code and verify.

To run this test, use:

    ./Build test_more

or

    make test_more

=cut

use Module::Build;

my $class = Module::Build->subclass(
    code => q(
        sub ACTION_test_more {
            my $self = shift;

            my %files = map { $_ => 1 } glob('t/more/*.t');
            $self->{properties}{test_files} = \%files;

            return $self->ACTION_test();
        }
    ),
);

$class->new(
        module_name => 'Module::Util',
        requires => {
            perl => '5.5.3',
        },
        build_requires => {
            'Test::More' => 0,
        },
        configure_requires => {
            'Module::Build' => '0.40',
        },
        script_files => [ glob("scripts/*") ],
        license => 'perl',
        create_makefile_pl => 'small',
        create_readme => 1,
    )->create_build_script;

