use Modern::Perl;
package Orbital::Transfer::System::Debian;
# ABSTRACT: Debian-based system
$Orbital::Transfer::System::Debian::VERSION = '0.001';
use Mu;
use Orbital::Transfer::Common::Setup;
use Orbital::Transfer::System::Debian::Meson;
use Orbital::Transfer::System::Docker;

use Orbital::Transfer::PackageManager::APT;
use Orbital::Transfer::RepoPackage::APT;

use Orbital::Transfer::EnvironmentVariables;
use Object::Util magic => 0;

lazy apt => method() {
	Orbital::Transfer::PackageManager::APT->new(
		runner => $self->runner
	);
};

lazy x11_display => method() {
	':99.0';
};

lazy environment => method() {
	Orbital::Transfer::EnvironmentVariables
		->new
		->$_tap( 'set_string', 'DISPLAY', $self->x11_display );
};

method _prepare_x11() {
	#system(qw(sh -e /etc/init.d/xvfb start));
	unless( fork ) {
		exec(qw(Xvfb), $self->x11_display);
	}
	sleep 3;
}

method _pre_run() {
	$self->_prepare_x11;
}

method _install() {
	if( Orbital::Transfer::System::Docker->is_inside_docker ) {
		# create a non-root user
		say STDERR "Creating user nonroot (this should only occur inside Docker)";
		system(qw(useradd -m notroot));
		system(qw(chown -R notroot:notroot /build));
	}
	my @packages = map {
		Orbital::Transfer::RepoPackage::APT->new( name => $_ )
	} qw(xvfb xauth);
	$self->runner->system(
		$self->apt->install_packages_command(@packages)
	) unless $self->apt->are_all_installed(@packages);
}

method install_packages($repo) {
	my @packages = map {
		Orbital::Transfer::RepoPackage::APT->new( name => $_ )
	} @{ $repo->debian_get_packages };

	$self->runner->system(
		$self->apt->install_packages_command(@packages)
	) if @packages && ! $self->apt->are_all_installed(@packages);

	if( grep { $_->name eq 'meson' } @packages ) {
		my $meson = Orbital::Transfer::System::Debian::Meson->new(
			runner => $self->runner,
			platform => $self,
		);
		$meson->install_pip3_apt($self->apt);
		$meson->setup;
	}
}

method process_git_path($path) {
	if( Orbital::Transfer::System::Docker->is_inside_docker ) {
		system(qw(chown -R notroot:notroot), $path);
	}
}

with qw(
	Orbital::Transfer::System::Role::Config
	Orbital::Transfer::System::Role::DefaultRunner
	Orbital::Payload::Environment::Perl::System::Role::PerlPathCurrent
	Orbital::Payload::Environment::Perl::System::Role::Perl
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::System::Debian - Debian-based system

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
