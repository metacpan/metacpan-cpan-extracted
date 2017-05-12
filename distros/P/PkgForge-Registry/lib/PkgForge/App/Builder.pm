package PkgForge::App::Builder; # -*-perl-*-
use strict;
use warnings;

# $Id: Builder.pm.in 16210 2011-03-02 09:01:32Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16210 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Registry/PkgForge_Registry_1_3_0/lib/PkgForge/App/Builder.pm.in $
# $Date: 2011-03-02 09:01:32 +0000 (Wed, 02 Mar 2011) $

our $VERSION = '1.3.0';

use English qw(-no_match_vars);

use Moose;
use MooseX::Types::Moose qw(Str);

extends qw(MooseX::App::Cmd::Command);

with qw(PkgForge::Registry::App);

sub abstract { return q{Manage builder entries in the registry} };

has 'name' => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_name',
    documentation => 'Builder name',
);

has 'platform' => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_platform',
    documentation => 'Builder platform name',
  );

has 'architecture' => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_arch',
    documentation => 'Builder platform architecture',
);

sub action_list {
    my ($self) = @_;

    my $schema = $self->registry->schema;

    my @builders = $schema->resultset('Builder')->search(
        {}, { order_by => 'name' } );

    if ( scalar @builders == 0 ) {
        print "Currently there are no builders registered\n";
    } else {
        print "Builder\t\tPlatform\tArchitecture\n";
        print "=============================================\n";

        for my $entry (@builders) {
            print $entry->name . "\t" . $entry->platform->name . "\t\t" . $entry->platform->arch . "\n";
        }
    }

    return;
}

sub action_delete {
    my ($self) = @_;

    $self->require_parameters('name');

    my $builder_name = $self->name;

    my $schema = $self->registry->schema;
    my $builder_rs  = $schema->resultset('Builder');

    my $builder = $builder_rs->search( { name => $builder_name } )->single;

    if ( !defined $builder ) {
        die "Cannot remove a builder named '$builder_name', it does not appear to exist.\n";
    }

    my $ok = eval { $schema->txn_do( sub { $builder->delete } ); };
    if ( !$ok || $EVAL_ERROR ) {
        die "Failed to delete builder '$builder_name': $EVAL_ERROR\n";
    } else {
        print "Successfully deleted builder '$builder_name'\n";
    }

    return;
}

sub action_add {
    my ($self) = @_;

    $self->require_parameters(qw/name platform architecture/);

    my $builder_name = $self->name;
    my $plat_name    = $self->platform;
    my $plat_arch    = $self->architecture;

    my $schema = $self->registry->schema;
    my $builder_rs  = $schema->resultset('Builder');
    my $platform_rs = $schema->resultset('Platform');

    my $matches = $builder_rs->search( { name => $builder_name } );

    if ( $matches->count > 0 ) {
        die "Cannot add a builder named '$builder_name', it already exists.\n";
    }

    # Find the platform entry

    my $platform = $platform_rs->search( { name => $plat_name,
                                           arch => $plat_arch } )->single;
    if ( !defined $platform ) {
        die "Failed to find the platform '$plat_name/$plat_arch', that must be registered and activated first.\n";
    }

    if ( !$platform->active ) {
        warn "The platform '$plat_name/$plat_arch' is not currently active\n";
    }

    # Add the new builder

    my $ok = eval {
        $schema->txn_do(
            sub { $builder_rs->create( { name     => $builder_name,
                                         platform => $platform->id } ) }
        );
    };
    if ( !$ok || $EVAL_ERROR ) {
        die "Failed to add builder '$builder_name' for platform $plat_name/$plat_arch: $EVAL_ERROR\n";
    } else {
        print "Successfully added builder '$builder_name' for platform $plat_name/$plat_arch\n";
    }

    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
=head1 NAME

PkgForge::App::Builder - Package Forge Registry App for managing build daemons

=head1 VERSION

This documentation refers to PkgForge::App::Builder version 1.3.0

=head1 SYNOPSIS

    pkgforge builder list

    pkgforge builder add --name foo_f13 --plat f13 --arch i386

    pkgforge builder del --name foo_f13

=head1 DESCRIPTION

This is a Package Forge application for managing the registered build
daemons. It makes it easy to list, add and delete build daemons for
particular target platforms.

It is not expected that this class will be used directly, it is
designed to provide a command for the pkgforge(1) command-line tool.

=head1 ATTRIBUTES

This class has the following attributes which are mapped into
command-line options when used via the C<pkgforge> application.

=over

=item configfile

This is the name of the file from which the Package Forge Registry
configuration should be loaded. If not specified then the default,
C</etc/pkgforge/registry.yml> will be used.

=item name

The unique name of the build daemon.

=item platform

The name of the target platform supported by the build daemon. For
example, C<f13> or C<sl5>.

=item architecture

The architecture of the target platform supported by the build
daemon. For example, C<i386> or C<x86_64>.

=back

=head1 SUBROUTINES/METHODS

The class has the following methods which are mapped into sub-commands
without the leading C<action_> for the C<pkgforge> application.

=over

=item action_list

Ths action lists all the registered build daemons. It does not use any
of the attributes (or command-line options).

=item action_add

This action adds a new build daemon. You must specify a unique name
for the daemon, the name of the platform and the architecture via the
relevant attributes (or command-line options). Note that it is not
possible to add a build daemon for a platform/architecture combination
which has not already been registered and activated.

=item action_delete

This action deletes the entry for a build daemon. You must specify the
name of the build daemon via the relevant attribute (or command-line
option).

It is not generally a good idea to remove a build daemon entry once it
has been used to carry out build jobs as the database keeps a log of
what has done and you will lose history.

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

    Copyright (C) 2010 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
