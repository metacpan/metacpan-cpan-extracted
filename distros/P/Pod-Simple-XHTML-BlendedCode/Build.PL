use strict;
use warnings;
use inc::latest 'Module::Build';

my $class = Module::Build->subclass(
	class => 'My::Builder',
	code  => <<'END_CODE',
sub ACTION_authortest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw< t xt/author > );
    $self->depends_on('test');

    return;
}


sub ACTION_releasetest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw< t xt/author xt/release > );
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
	module_name        => 'Pod::Simple::XHTML::BlendedCode',
	license            => 'perl',
	dist_author        => 'Curtis Jewell <csjewell@cpan.org>',
	dist_version_from  => 'lib/Pod/Simple/XHTML/BlendedCode.pm',
	create_readme      => 1,
	create_license     => 1,
	create_makefile_pl => 'small',
	configure_requires => { 'Module::Build' => '0.33', },
	requires           => {
		'perl'               => '5.008001',
		'parent'             => '0.223',
		'PPI::HTML'          => '1.08',
		'Pod::Simple::XHTML' => '3.14',
		'Pod::Parser'        => '1.37',
		'IO::String'         => '1.08',
	},
	build_requires => {
		'Test::More'        => '0.88',
		'IO::CaptureOutput' => '0.1102',
		'Test::LongString'  => '0.13',
		'File::Slurp'       => '9999.13',
	},
	meta_merge => {
		resources => {
			homepage => 'http://csjewell.comyr.com/',
			bugtracker =>
'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Simple-XHTML-BlendedCode',
			repository =>
			  'http://bitbucket.org/csjewell/pod-simple-xhtml-blendedcode'
		},
	},
	add_to_cleanup => [ 'Pod-Simple-XHTML-BlendedCode-*', ],
);

$builder->create_build_script();
