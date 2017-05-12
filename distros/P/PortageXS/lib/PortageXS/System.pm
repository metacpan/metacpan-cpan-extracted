use strict;
use warnings;

package PortageXS::System;
BEGIN {
  $PortageXS::System::AUTHORITY = 'cpan:KENTNL';
}
{
  $PortageXS::System::VERSION = '0.3.1';
}
# ABSTRACT: System interactions role for PortageXS
# -----------------------------------------------------------------------------
#
# PortageXS::System
#
# author      : Christian Hartmann <ian@gentoo.org>
# license     : GPL-2
# header      : $Header: /srv/cvsroot/portagexs/trunk/lib/PortageXS/System.pm,v 1.2 2007/04/09 15:03:51 ian Exp $
#
# -----------------------------------------------------------------------------
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# -----------------------------------------------------------------------------


use Role::Tiny;
# Description:
# Executes $program and returns it's returncode.
# $returncode=cmdExecute($program);
# (0 = ok ; 1 = error)
sub cmdExecute {
	my $command	= shift;
	my $rc		= 0xffff & system($command);

	if ($rc == 0) {
		return $rc;
	}
	elsif ($rc == 0xff00) {
		return $rc;
	}
	elsif (($rc & 0xff) == 0) {
		$rc >>= 8;
		return $rc;
	}
	else {
		if ($rc & 0x80) {
			$rc &= ~0x80;
			return $rc;
		}
		return $rc;
	}
}

# Description:
# Returns the homedir of the current user.
# $dir=$pxs->getHomedir();
sub getHomedir {
	my $self	= shift;
	my $homedir	= '';
	if (!$self->{'CACHE'}{'System'}{'getHomedir'}{'homedir'}) {
		$homedir=`echo ~`;
		chomp($homedir);
		$self->{'CACHE'}{'System'}{'getHomedir'}{'homedir'}=$homedir;
		return $homedir;
	}
	else {
		return $self->{'CACHE'}{'System'}{'getHomedir'}{'homedir'};
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PortageXS::System - System interactions role for PortageXS

=head1 VERSION

version 0.3.1

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"PortageXS::System",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 AUTHORS

=over 4

=item *

Christian Hartmann <ian@gentoo.org>

=item *

Torsten Veller <tove@gentoo.org>

=item *

Kent Fredric <kentnl@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Christian Hartmann.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
