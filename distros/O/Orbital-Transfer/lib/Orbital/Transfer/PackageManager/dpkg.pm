use Modern::Perl;
package Orbital::Transfer::PackageManager::dpkg;
# ABSTRACT: dpkg package manager
$Orbital::Transfer::PackageManager::dpkg::VERSION = '0.001';
use Mu;
use Orbital::Transfer::Common::Setup;
use aliased 'Orbital::Transfer::Runnable';
use Try::Tiny;

method installed_version( $package ) {
	try {
		my ($show_output) = $self->runner->capture(
			Runnable->new(
				command => [ qw(dpkg-query --show), $package->name ]
			)
		);

		chomp $show_output;
		my ($package_name, $version) = split "\t", $show_output;

		$version;
	} catch {
		die "dpkg-query: no packages found matching @{[ $package->name ]}";
	}
}

with qw(Orbital::Transfer::Role::HasRunner);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::PackageManager::dpkg - dpkg package manager

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
