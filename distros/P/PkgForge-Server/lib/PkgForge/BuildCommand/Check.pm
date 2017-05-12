package PkgForge::BuildCommand::Check; # -*-perl-*-
use strict;
use warnings;

our $VERSION = '1.1.10';

# $Id: Check.pm.in 16781 2011-04-22 09:41:46Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16781 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/BuildCommand/Check.pm.in $
# $Date: 2011-04-22 10:41:46 +0100 (Fri, 22 Apr 2011) $

use Moose::Role;
use MooseX::Types::Moose qw(Str);

with 'PkgForge::BuildCommand';

no Moose::Role;

1;
__END__

=head1 NAME

PkgForge::Check - 

=head1 VERSION

This documentation refers to PkgForge::Check version 1.1.10

=head1 USAGE

=head1 DESCRIPTION

=head1 REQUIRED ARGUMENTS

=head1 OPTIONS

=over 4

=item

=back

=head1 CONFIGURATION

=head1 EXIT STATUS

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

=head1 DEPENDENCIES

This application requires

=head1 SEE ALSO

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
