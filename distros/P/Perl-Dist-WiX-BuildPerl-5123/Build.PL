use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
	class => 'My::Builder',
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
    module_name              => 'Perl::Dist::WiX::BuildPerl::5123',
    license                  => 'perl',
    dist_author              => [ 'Curtis Jewell <CSJewell@cpan.org>' ],
    dist_version_from        => 'lib/Perl/Dist/WiX/BuildPerl/5123.pm',
	create_readme            => 1,
	create_license           => 1,
	# Do not remove. Directories in t/ require it.
	recursive_test_files     => 1,
	requires => {
		'perl'              => '5.010',
		'Perl::Dist::WiX'   => '1.500',
		'Moose::Role'       => '2.00',
		'File::ShareDir'    => '1.02',
	},
	configure_requires => {
		'Module::Build'     => '0.36',
	},
	build_requires => {
		'Test::More'        => '0.88',
		'Test::Perl::Dist'  => '0.300',
	},
	meta_merge => {
		resources => {
			homepage    => 'http://www.curtisjewell.name/perl/',
			bugtracker  => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX',
			repository  => 'http://hg.curtisjewell.name/Perl-Dist-WiX-BuildPerl-5123/',
			IRC         => 'irc://irc.perl.org/#win32',
		},
	},
	share_dir => {
		module => {
			'Perl::Dist::WiX::BuildPerl::5123'  => 'share-5123',
		}
	},
    add_to_cleanup      => [ 'Perl-Dist-WiX-BuildPerl-5123-*', ],
);

$builder->create_build_script();
