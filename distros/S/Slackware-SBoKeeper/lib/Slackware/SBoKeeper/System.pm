package Slackware::SBoKeeper::System;
our $VERSION = '2.03';
use 5.016;
use strict;
use warnings;

use File::Basename;

my $SLACKWARE_VERSION_FILE = "/etc/slackware-version";

sub _slackware_version {

	# If Slackware version file does not exist, we're probably not on a
	# Slackware system.
	unless (-e $SLACKWARE_VERSION_FILE) {
		return undef;
	}

	open my $fh, '<', $SLACKWARE_VERSION_FILE
		or die "Failed to open $SLACKWARE_VERSION_FILE for reading: $!\n";

	my $l = readline $fh;
	chomp $l;

	# Some Slackware version numbers will have a third number, but we'll ignore
	# it. Most software uses the major.minor numbering scheme.
	my ($ver) = $l =~ /^Slackware (\d+\.\d+)/;

	unless ($ver) {
		warn "Bad $SLACKWARE_VERSION_FILE?\n";
		return undef;
	}

	return $ver;

}

my $SLACKWARE_VERSION = _slackware_version();
my $IS_SLACKWARE = defined $SLACKWARE_VERSION;

my $PKGTOOL_LOGS = undef;
my %PACKAGES;

if ($IS_SLACKWARE) {

	$PKGTOOL_LOGS = $SLACKWARE_VERSION < 15
		? '/var/log/packages'
		: '/var/lib/pkgtools/packages'
	;

	foreach my $pkgf (glob "$PKGTOOL_LOGS/*") {
		$pkgf = basename($pkgf);
		# Copied this regex from sbopkg
		$pkgf =~ /(.*)-([^-]*)-([^-]*)-([0-9]*)(.*)/ or next;
		$PACKAGES{$1} = {
			Version => $2,
			Arch    => $3,
			Build   => $4,
			Tag     => $5,
		};
	}

}

sub is_slackware { $IS_SLACKWARE };

sub version { $SLACKWARE_VERSION };

sub pkgtool_logs { $PKGTOOL_LOGS };

sub packages { sort keys %PACKAGES };

sub packages_by_tag {

	my $self = shift;
	my $tag  = shift;

	return grep { $PACKAGES{$_}->{Tag} eq $tag } $self->packages();

}

sub installed {

	my $self = shift;
	my $pkg  = shift;

	return defined $PACKAGES{$pkg};

}

1;

=head1 NAME

Slackware::SBoKeeper::System - Slackware system information

=head1 SYNOPSIS

 use Slackware::SBoKeeper::System;
 ...

=head1 DESCRIPTION

Slackware::SBoKeeper::System is a module that provides miscellaneous
information about the Slackware system. This module is not meant to be used
outside of L<sbokeeper>. If you are looking for L<sbokeeper> user documentation,
please consult its manual.

Slackware::SBoKeeper::System works similarly to L<File::Spec>, it is meant to
be used like an object. That means the following subroutines should be invoked
as methods of C<Slackware::SBoKeeper::System>.

=head1 METHODS

=over 4

=item is_slackware()

Returns true if we're on a Slackware system, false if we're not.

=item version()

Returns Slackware system's version number, following the major.minor numbering
scheme. Returns C<undef> on non-Slackware systems.

=item pkgtool_logs()

Returns pkgtool log directory. C<undef> on non-Slackware systems.

=item packages()

Returns list of installed packages.

=item packages_by_tag($tag)

Returns list of installed packages with the tag C<$tag>. For example, to get
all SlackBuilds.org packages installed on your system:

  Slackware::SBoKeeper::System->packages_by_tag('_SBo');

=item installed($pkg)

Returns true if C<$pkg> is installed, false if not.

=back

=head1 FILES

=over 4

=item F</etc/slackware-version>

File present on all Slackware systems that contains the Slackware version
number.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

=head1 COPYRIGHT

Copyright (C) 2024-2025, Samuel Young

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

=head1 SEE ALSO

L<sbokeeper>

=cut
