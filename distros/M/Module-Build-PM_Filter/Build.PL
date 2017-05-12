use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass( code => <<'SUBCLASS' );

sub ACTION_showdistdir {
    my $self = shift;

    print $self->dist_dir(),"\n";
}
SUBCLASS

my $builder = Module::Build->new(
    module_name         => 'Module::Build::PM_Filter',
    license             => 'gpl',
    dist_author         => 'Victor Moral <victor@taquiones.net>',
    dist_version_from   => 'lib/Module/Build/PM_Filter.pm',
    requires => {
        'Test::More'                =>  0,
        'Module::Build'             =>  0,
        'File::Copy::Recursive'     =>  0,
    },
    add_to_cleanup      => [ 
            'Module-Build-PM_Filter-*',
            'examples/MyModule-*',
            'libmodule-build-pm-filter-perl*',
            ],
);

$builder->create_build_script();
