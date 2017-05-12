use 5.006;
use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'Module::Build::WithDebuild',
    code => q{
        sub ACTION_debuild {
            system("debuild -i -us -uc -b");
        }
    },
    );

my $builder = $class->new(
    module_name         => 'Pod::Coverage::mop',
    license             => 'perl',
    dist_author         => q{Fabrice Gabolde <fabrice.gabolde@gmail.com>},
    dist_version_from   => 'lib/Pod/Coverage/mop.pm',
    dist_abstract       => 'Pod::Coverage subclass to calculate coverage for mop-based classes',
    configure_requires => { 'Module::Build' => '0.36_14' },
    requires => {
        'perl' => 5.012, # we don't use anything that requires more...
        'mop' => 0,      # except for this
        'Pod::Coverage::CountParents' => 0,
    },
    add_to_cleanup      => [ 'Pod-Coverage-mop-*' ],
    meta_merge          => { resources =>
                             { repository => 'https://bitbucket.org/fgabolde/pod-coverage-mop' } },
);

$builder->create_build_script();
