use Modern::Perl;
package Orbital::Transfer::PackageManager::APT;
# ABSTRACT: Package manager for apt-based systems
$Orbital::Transfer::PackageManager::APT::VERSION = '0.001';
use Mu;
use Orbital::Transfer::Common::Setup;
use aliased 'Orbital::Transfer::Runnable';
use Orbital::Transfer::PackageManager::dpkg;
use List::AllUtils qw(all);
use File::Which;

classmethod loadable() {
	all {
		defined which($_)
	} qw(apt-cache apt-get);
}

lazy dpkg => method() {
	Orbital::Transfer::PackageManager::dpkg->new(
		runner => $self->runner,
	);
};

method installed_version( $package ) {
	$self->dpkg->installed_version( $package );
}

method installable_versions( $package ) {
	try {
		my ($show_output) = $self->runner->capture(
			Runnable->new(
				command => [ qw(apt-cache show), $package->name ],
			)
		);

		my @package_info = split "\n\n", $show_output;

		map { /^Version: (\S+)$/ms } @package_info;
	} catch {
		die "apt-cache: Unable to locate package @{[ $package->name ]}";
	};
}

method are_all_installed( @packages ) {
	try {
		all { $self->installed_version( $_ ) } @packages;
	} catch { 0 };
}

method install_packages_command( @package ) {
	Runnable->new(
		command => [
			qw(apt-get install -y --no-install-recommends),
			map { $_->name } @package
		],
		admin_privilege => 1,
	);
}

with qw(Orbital::Transfer::Role::HasRunner);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::PackageManager::APT - Package manager for apt-based systems

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
