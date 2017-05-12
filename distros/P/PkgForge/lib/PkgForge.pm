package PkgForge; # -*-perl-*-
use strict;
use warnings;

# $Id: PkgForge.pm.in 15202 2011-01-05 12:03:38Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15202 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge/PkgForge_1_4_8/lib/PkgForge.pm.in $
# $Date: 2011-01-05 12:03:38 +0000 (Wed, 05 Jan 2011) $

our $VERSION = '1.4.8';

1;
__END__

=head1 NAME

PkgForge - The Package Forge build farm system

=head1 VERSION

This documentation refers to PkgForge version 1.4.8

=head1 DESCRIPTION

Package Forge (PkgForge) is a build farm system. A framework is
provided to allow multiple platforms (e.g. Redhat and Debian Linux as
well as MacOSX) to build binary software packages from the same source
packages.

The build jobs are registered and scheduled via the Registry which is
based around a PostgreSQL database. See L<PkgForge::Registry> for
details.

The submitted jobs are processed and built using server daemons. See
L<PkgForge::Server> for details.

There is an, optional, web interface which provides access to the
information stored in the Registry. See L<PkgForge::Web> for details.

=head1 SEE ALSO

L<PkgForge::Registry>, L<PkgForge::Server>, L<PkgForge::Web>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux5, Fedora13

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2011 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
