use Modern::Perl;
package Orbital::Transfer::Repo::Role::DevopsYaml;
# ABSTRACT: A role for reading devops configuration from YAML
$Orbital::Transfer::Repo::Role::DevopsYaml::VERSION = '0.001';
use Mu::Role;
use YAML;

use Orbital::Transfer::Common::Setup;

lazy devops_config_path => method() {
	File::Spec->catfile( $self->directory, qw(maint devops.yml) );
};

lazy devops_data => method() {
	YAML::LoadFile( $self->devops_config_path );
};

method debian_get_packages() {
	my $data = [];
	if( -r $self->devops_config_path ) {
		push @$data, @{ $self->devops_data->{native}{debian}{packages} || [] };
	}

	return $data;
}

method homebrew_get_packages() {
	my $data = [];
	if( -r $self->devops_config_path ) {
		push @$data, @{ $self->devops_data->{native}{'macos-homebrew'}{packages} || [] };
	}

	return $data;
}

method msys2_mingw64_get_packages() {
	my $data = [];
	if( -r $self->devops_config_path ) {
		push @$data, @{ $self->devops_data->{native}{'msys2-mingw64'}{packages} || [] };
	}

	return $data;
}

method chocolatey_get_packages() {
	my $data = [];
	if( -r $self->devops_config_path ) {
		push @$data, @{ $self->devops_data->{native}{'chocolatey'}{packages} || [] };
	}

	return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::Repo::Role::DevopsYaml - A role for reading devops configuration from YAML

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
