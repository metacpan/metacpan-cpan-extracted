use strict;
use warnings;
use Module::Build;
my $class = Module::Build->subclass
(
    class => 'JPEACOCK::Builder',
    code => q{
	sub ACTION_dist{
	    my $self = shift;
	    $self->do_system('hg log --style changelog > Changes');
	    $self->SUPER::ACTION_dist();
	}
    }
);

my $builder = $class->new(
    module_name         => 'Module::Starter::XSimple',
    license             => 'perl',
    dist_author         => 'John Peacock <jpeacock@cpan.org>',
    dist_version_from   => 'lib/Module/Starter/XSimple.pm',
    requires => {
	'Module::Build'   => 0.38,
	'Module::Starter' => 1.58,
	'Test::More'      => 0.98,
	'version'         => 0.88,
	'Devel::PPPort'   => 3.06,
	'Path::Class'     => 0.26,
    },
    configure_requires => {
	'Module::Build'   => 0.38,
    },
    add_to_cleanup      => [ 'Module-Starter-XSimple-*' ],
);

$builder->create_build_script();
