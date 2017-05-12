use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
	class => 'MSCSJ::Builder',
	code  => <<'END_CODE',

sub ACTION_authortest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw( t xt/author ) );
    $self->depends_on('test');

    return;
}



sub ACTION_releasetest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw( t xt/author xt/release ) );
    $self->depends_on('test');

    return;
}



sub ACTION_manifest {
    my ($self, @arguments) = @_;

    if (-e 'MANIFEST') {
        unlink 'MANIFEST' or die "Can't unlink MANIFEST: $!";
    }

    return $self->SUPER::ACTION_manifest(@arguments);
}
END_CODE
);


my $builder = $class->new(
    module_name         => 'Module::Starter::CSJEWELL',
    license             => 'perl',
    dist_author         => 'Curtis Jewell <CSJewell@cpan.org>',
    dist_version_from   => 'lib/Module/Starter/CSJEWELL.pm',
	create_readme       => 1,
	create_license      => 1,
	create_makefile_pl  => 'small',
	configure_requires  => {
        'Module::Build'       => '0.33',
	},
    requires            => {
	    'perl'              => '5.008001',
        'Module::Starter'   => '1.52',
		'parent'            => '0.221',
		'Software::License' => '0.012',
		'Pod::Readme'       => '0.09',
    },
	build_requires      => {
        'Test::More'        => '0.88',
	},
	meta_merge          => {
        resources       => {
            homepage    => 'http://csjewell.comyr.com/perl/',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Starter-CSJEWELL',
            repository  => 'http://bitbucket.org/csjewell/module-starter-csjewell/'
        },
    },
    add_to_cleanup      => [ 'Module-Starter-CSJEWELL-*', ],
);

$builder->create_build_script();
