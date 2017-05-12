use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
	class => 'My::Builder',
	code  => <<'END_CODE',
sub ACTION_authortest {
    my ($self) = @_;

    $self->depends_on('build');

    $self->test_files( qw( t xt/author ) );
    $self->depends_on('test');

    return;
}



sub ACTION_releasetest {
    my ($self) = @_;

    $self->depends_on('build');

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

sub ACTION_distmeta {
    my ($self) = @_;
	
    $self->depends_on('manifest');
	
    return $self->SUPER::ACTION_distmeta();
}
END_CODE
);


my $builder = $class->new(
    module_name              => 'Perl::Dist::Strawberry::BuildPerl::5123',
    license                  => 'perl',
    dist_author              => [ 'Curtis Jewell <CSJewell@cpan.org>' ],
    dist_version_from        => 'lib/Perl/Dist/Strawberry/BuildPerl/5123.pm',
	create_readme            => 1,
	create_license           => 1,
	configure_requires       => {
        'Module::Build'      => '0.33',
	},
    requires => {
        'perl'                   => '5.010',	
		'Perl::Dist::Strawberry' => '2.11_10',
		'Moose::Role'            => '0.90',
		'File::ShareDir'         => '1.02',
    },
	build_requires => {
        'Test::More'          => '0.88',
	},
    meta_merge     => {
        resources => {
            homepage    => 'http://csjewell.comyr.com/perl/',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Dist-Strawberry-BuildPerl-5123',
			repository  => 'http://hg.curtisjewell.name/Perl-Dist-Strawberry-BuildPerl-5123',
#			IRC         => 'irc://irc.perl.org/#win32',
        },
    },
	share_dir => {
		module => {
			'Perl::Dist::Strawberry::BuildPerl::5123' => 'share',
		}
	},
    add_to_cleanup      => [ 'Perl-Dist-Strawberry-BuildPerl-5123-*', ],
);

$builder->create_build_script();
