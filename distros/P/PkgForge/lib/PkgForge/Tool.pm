package PkgForge::Tool; # -*-perl-*-
use strict;
use warnings;

# $Id: Tool.pm.in 15205 2011-01-05 16:47:00Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15205 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge/PkgForge_1_4_8/lib/PkgForge/Tool.pm.in $
# $Date: 2011-01-05 16:47:00 +0000 (Wed, 05 Jan 2011) $

our $VERSION = '1.4.8';

use Moose;

extends qw(MooseX::App::Cmd);

use constant plugin_search_path => 'PkgForge::App';
use constant allow_any_unambiguous_abbrev => 1;

__PACKAGE__->meta->make_immutable;
no Moose;

1;
__END__

=head1 NAME

PkgForge::Tool - Package Forge application manager

=head1 VERSION

This documentation refers to PkgForge::Tool version 1.4.8

=head1 SYNOPSIS

    use PkgForge::Tool;

    PkgForge::Tool->run;

=head1 DESCRIPTION

This class is used to parse a command-line and select the correct
class in the L<PkgForge::App> namespace to execute the requested
command. Typically you would not use this class directly, it mainly
exists to make the pkgforge(1) command as simple as possible.

=head1 SUBROUTINES/METHODS

=over

=item run

This is the method which does all the work.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::App::Cmd>.

=head1 SEE ALSO

L<PkgForge>

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

    Copyright (C) 2010 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut

