package PkgForge::Registry::Schema; # -*-perl-*-
use strict;
use warnings;

# $Id: Schema.pm.in 15097 2010-12-13 06:25:02Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15097 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Registry/PkgForge_Registry_1_3_0/lib/PkgForge/Registry/Schema.pm.in $
# $Date: 2010-12-13 06:25:02 +0000 (Mon, 13 Dec 2010) $

our $VERSION = '1.3.0';

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

1;
__END__

=head1 NAME

PkgForge::Registry::Schema - The Package Forge registry schema class

=head1 VERSION

This documentation refers to PkgForge::Registry::Schema version 1.3.0

=head1 SYNOPSIS

   use PkgForge::Registry::Schema;

   my $schema
        = PkgForge::Registry::Schema->connect( $dsn, $user, $pass, \%opts );

=head1 DESCRIPTION

This module provides access to the DBIx::Class layer which is used to
provide an interface to the Package Forge registry database.

=head1 SUBROUTINES/METHODS

This class has one method:

=over

=item connect( $dsn, $user, $pass, \%options )

This takes the DBI Data Source Name (DSN) and, optionally, a username
and password to be used for connecting to the database. It can also
take a reference to a hash of options which control how the DBI layer
functions. A schema object is returned, see L<DBIx::Class::Schema> for
details of the available methods for this object.

=back

=head1 CONFIGURATION AND ENVIRONMENT

This class is not normally loaded directly, instead the
L<PkgForge::Registry> module has support for retrieving the database
configuration parameters from a configuration file, see that module
for details.

=head1 DEPENDENCIES

This module requires L<DBIx::Class>, you will also need a DBI driver
module such as L<DBD::Pg>.

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
