package PkgForge::App::Platform; # -*-perl-*-
use strict;
use warnings;

# $Id: Platform.pm.in 16211 2011-03-02 09:01:58Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16211 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Registry/PkgForge_Registry_1_3_0/lib/PkgForge/App/Platform.pm.in $
# $Date: 2011-03-02 09:01:58 +0000 (Wed, 02 Mar 2011) $

our $VERSION = '1.3.0';

use Moose;
use MooseX::Types::Moose qw(Str);

extends qw(MooseX::App::Cmd::Command);

with qw(PkgForge::Registry::App);

sub abstract { return q{Manage platform entries in the registry} };

has 'name' => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_name',
    documentation => 'Platform name',
);

has 'architecture' => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_arch',
    documentation => 'Platform architecture',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub action_list {
    my ($self) = @_;

    my $schema = $self->registry->schema;

    my @platforms = $schema->resultset('Platform')->search(
        {}, { order_by => [qw/name arch/] } );

    if ( scalar @platforms == 0 ) {
        print "Currently there are no platforms registered\n";
    } else {
        print "Name\tArchitecture\tActive\tAuto\n";
        print "=====================================\n";

        for my $entry (@platforms) {
            print $entry->name . "\t" . $entry->arch . "\t\t" . $entry->active . "\t" . $entry->auto . "\n";
      }
    }

    return;
}

sub action_add {
    my ($self) = @_;

    $self->require_parameters(qw/name architecture/);

    my $name = $self->name;
    my $arch = $self->architecture;

    my $schema = $self->registry->schema;
    my $rs = $schema->resultset('Platform');

    my $matches = $rs->search( { name => $name, arch => $arch } );

    if ( $matches->count >= 1 ) {
        die "Cannot add $name/$arch platform, it already exists.\n";
    }

    my $ok = eval {
        $schema->txn_do( sub { $rs->create( { name => $name,
                                              arch => $arch } ) } )
    };
    if ( !$ok || $@ ) {
        die "Failed to add $name/$arch platform: $@\n";
    } else {
        print "Successfully added $name/$arch platform\n";
    }

    return;
}

sub action_activate {
    my ($self) = @_;

    $self->require_parameters(qw/name architecture/);

    my $name = $self->name;
    my $arch = $self->architecture;

    my $schema = $self->registry->schema;
    my $rs = $schema->resultset('Platform');

    my $platform = $rs->search( { name => $name, arch => $arch } )->single;

    if ( !defined $platform ) {
        die "Cannot modify $name/$arch platform, it does not exist.\n";
    }

    $platform->active(1);

    my $ok = eval { $schema->txn_do( sub { $platform->update } ) };
    if ( !$ok || $@ ) {
        die "Failed to activate $name/$arch platform: $@\n";
    } else {
        print "Successfully activated $name/$arch platform\n";
    }

    return;
}

sub action_setauto {
    my ($self) = @_;

    $self->require_parameters(qw/name architecture/);

    my $name = $self->name;
    my $arch = $self->architecture;

    my $schema = $self->registry->schema;
    my $rs = $schema->resultset('Platform');

    my $platform = $rs->search( { name => $name, arch => $arch } )->single;

    if ( !defined $platform ) {
        die "Cannot modify $name/$arch platform, it does not exist.\n";
    }

    $platform->auto(1);

    my $ok = eval { $schema->txn_do( sub { $platform->update } ) };
    if ( !$ok || $@ ) {
        die "Failed to set auto on $name/$arch platform: $@\n";
    } else {
        print "Successfully set auto on $name/$arch platform\n";
    }

    return;
}

sub action_deactivate {
    my ($self) = @_;

    $self->require_parameters(qw/name architecture/);

    my $name = $self->name;
    my $arch = $self->architecture;

    my $schema = $self->registry->schema;
    my $rs = $schema->resultset('Platform');

    my $platform = $rs->search( { name => $name, arch => $arch } )->single;

    if ( !defined $platform ) {
        die "Cannot modify $name/$arch platform, it does not exist.\n";
    }

    $platform->active(0);
    $platform->auto(0);

    my $ok = eval { $schema->txn_do( sub { $platform->update } ) };
    if ( !$ok || $@ ) {
        die "Failed to deactivate $name/$arch platform: $@\n";
    } else {
        print "Successfully deactivated $name/$arch platform\n";
    }

    return;
}

1;
=head1 NAME

PkgForge::App::Platform - Package Forge Registry App for managing platforms

=head1 VERSION

This documentation refers to PkgForge::App::Platform version 1.3.0

=head1 SYNOPSIS

    pkgforge platform list

    pkgforge platform add --name f13 --arch i386

    pkgforge platform activate --name f13 --arch i386

    pkgforge platform setauto --name f13 --arch i386

=head1 DESCRIPTION

This is a Package Forge application for managing the registered build
platforms. It makes it easy to list, add and manage platforms.

It is not expected that this class will be used directly, it is
designed to provide a command for the pkgforge(1) command-line tool.

=head1 ATTRIBUTES

This class has the following attributes which are mapped into
command-line options when used via the C<pkgforge> application.

=over

=item name

This is the name of the platform. For example, C<sl5> or C<f13>.

=item architecture

This is the name of the architecture for the platform. For example,
C<i386> or C<x86_64>.

=back

=head1 SUBROUTINES/METHODS

The class has the following methods which are mapped into sub-commands
without the leading C<action_> for the C<pkgforge> application.

=over

=item action_list

Ths action lists all the registered build platforms. It does not use any
of the attributes (or command-line options).

=item action_add

This action adds a new platform. You must specify the values for the
name and the architecture attributes. Note that a platform is NOT
activated automatically, you must do that in a separate step.

=item action_activate

This action activates a platform. You must specify the values for the
name and the architecture attributes. Once a platform is activated new
tasks will be registered for it whenever a new job is submitted.

=item action_deactivate

This action deactivates a platform. You must specify the values for
the name and the architecture attributes. A platform which is not
active will not get any new tasks registered. This is particularly
useful when a platform is no longer supported but you cannot remove it
from the registry as there is lots of associated history from old
completed jobs.

=item setauto

This action sets the C<auto> flag on a platform. When this flag is
true pkgforge tasks will be automatically registered for a platform
whenever the user requests the C<auto> set of platforms. If the auto
flag is false then it is still possible to register tasks for a
platform, as long as it is marked as C<active>. The user must request
the C<all> set or explicitly list the platform when it is not marked
as C<auto>.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The Package Forge Registry configuration file can be specified via the
C<configfile> attribute (or command-line option). If not specified
then the default, C</etc/pkgforge/registry.yml> will be used.

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::App::Cmd> and
L<MooseX::Types>.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Registry>, pkgforge(1)

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

    Copyright (C) 2010-2011 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
