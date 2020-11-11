use Modern::Perl;
package Orbital::Transfer::System::Debian::Meson;
# ABSTRACT: Install and setup meson build system
$Orbital::Transfer::System::Debian::Meson::VERSION = '0.001';
use Mu;
use Orbital::Transfer::Common::Setup;
use Orbital::Transfer::EnvironmentVariables;
use aliased 'Orbital::Transfer::Runnable';
use Object::Util magic => 0;

has platform => (
	is => 'ro',
	required => 1,
);

has runner => (
	is => 'ro',
	required => 1,
);

method environment() {
	my $py_user_base_bin = $self->runner->capture(
		Runnable->new(
			command => [ qw(python3 -c), "import site, os; print(os.path.join(site.USER_BASE, 'bin'))" ],
			environment => $self->platform->environment
		)
	);
	chomp $py_user_base_bin;

	my $py_user_site_pypath = $self->runner->capture(
		Runnable->new(
			command => [ qw(python3 -c), "import site; print(site.USER_SITE)" ],
			environment => $self->platform->environment
		)
	);
	chomp $py_user_site_pypath;
	Orbital::Transfer::EnvironmentVariables
		->new
		->$_tap( 'prepend_path_list', 'PATH', [ $py_user_base_bin ] )
		->$_tap( 'prepend_path_list', 'PYTHONPATH', [ $py_user_site_pypath ] )
}

method setup() {
	if( $> != 0 ) {
		warn "Not installing meson";
	} else {
		$self->runner->system(
			Runnable->new(
				command => $_,
				environment => $self->environment,
			)
		) for(
			[ qw(pip3 install --user -U setuptools wheel) ],
			[ qw(pip3 install --user -U meson) ],
		);
	}
}

method install_pip3_apt( $apt ) {
	my $pip3 = Orbital::Transfer::RepoPackage::APT->new( name => 'python3-pip' );
	$self->runner->system(
		$apt->install_packages_command( $pip3 )
	) unless $apt->$_try( installed_version => $pip3 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::System::Debian::Meson - Install and setup meson build system

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
