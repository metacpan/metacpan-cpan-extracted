package PkgForge::Registry::Role; # -*-perl-*-
use strict;
use warnings;

# $Id: Role.pm.in 15133 2010-12-15 10:36:37Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15133 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Registry/PkgForge_Registry_1_3_0/lib/PkgForge/Registry/Role.pm.in $
# $Date: 2010-12-15 10:36:37 +0000 (Wed, 15 Dec 2010) $

our $VERSION = '1.3.0';

use PkgForge::Registry ();

use Moose::Role;
use Moose::Util::TypeConstraints;

# This subtype is designed to allow the caller to specify either a
# hashref, arrayref or a string (i.e. a path to the configuration
# file) and have it automatically converted into a PkgForge::Registry
# object.

subtype 'PkgForgeRegistry' => as class_type('PkgForge::Registry');

coerce 'PkgForgeRegistry'
    => from 'Str'
        => via { PkgForge::Registry->new_with_config( configfile => $_ ) }
    => from 'HashRef'
        => via { PkgForge::Registry->new( %{$_} ) }
    => from 'ArrayRef'
        => via { PkgForge::Registry->new( @{$_} ) };

has 'registry' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    isa     => 'PkgForgeRegistry',
    lazy    => 1,
    coerce  => 1,
    builder => '_build_registry',
    documentation => 'Package Forge Registry',
);

sub _build_registry {
    return PkgForge::Registry->new_with_config();
}

no Moose::Role;
1;

__END__

=head1 NAME

PkgForge::Registry::Role - Moose role for classes which use the PkgForge Registry

=head1 VERSION

This documentation refers to PkgForge::Registry::Role version 1.3.0

=head1 SYNOPSIS

     Package Foo;

     use Moose;

     with 'PkgForge::Registry::Role';

=head1 DESCRIPTION

This is a Moose role which adds a C<registry> attribute to your class
which gives access to a L<PkgForge::Registry> object in an easy to use
way.

=head1 ATTRIBUTES

This role adds one attribute to a class:

=over

=item registry

This attribute can be specified as either a string, hash reference or
array reference. When a string is passed in it is assumed that this is
the path to a configuration file name and C<new_with_config> is
called. When an rray-reference or hash-reference is used the
data-structure will be dereferenced appropriately and passed into the
C<new> method. If no value is specified for this attribute then
C<new_with_config> is called and the default configuration file will
be used.

=back

=head1 SUBROUTINES/METHODS

There are no methods or subroutines associated with this role.

=head1 CONFIGURATION AND ENVIRONMENT

By default the L<PkgForge::Registry> object will use the configuration
file C</etc/pkgforge/registry.yml> if it exists. That file can be
overridden by passing a different file name as the value for the
C<registry> attribute.

=head1 DEPENDENCIES

This module is powered by L<Moose>.

=head1 SEE ALSO

L<PkgForge> and L<PkgForge::Registry>

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
