package PkgForge::Registry::App; # -*-perl-*-
use strict;
use warnings;

# $Id: App.pm.in 15097 2010-12-13 06:25:02Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15097 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Registry/PkgForge_Registry_1_3_0/lib/PkgForge/Registry/App.pm.in $
# $Date: 2010-12-13 06:25:02 +0000 (Mon, 13 Dec 2010) $

our $VERSION = '1.3.0';

use PkgForge::Registry ();
use Text::Abbrev ();

use Moose::Role;
use MooseX::Types::Moose qw(Str);

has 'configfile' => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_configfile',
    documentation => 'Configuration file',
);

has 'registry' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    isa     => 'PkgForge::Registry',
    lazy    => 1,
    builder => '_build_registry',
    documentation => 'Package Forge Registry',
);

sub _build_registry {
    my ($self) = @_;

    my %params;
    if ( $self->has_configfile ) {
        %params = ( configfile => $self->configfile );
    }

    return PkgForge::Registry->new_with_config(%params);
}

sub require_parameters {
    my ( $self, @params ) = @_;

    for my $param (@params) {
        my $attr = $self->meta->get_attribute($param);
        if ( !defined $attr ) {
            die "This class does not have an attribute named '$param'\n";
        }

        if ( ! $attr->has_value($self) ) {
            die "Missing '$param' which is a required attribute\n";
        }
    }

    return;
}

sub actions_list {
    my ($self) = @_;

    my @actions;
    for my $method ( $self->meta->get_method_list ) {
        if ( $method =~ m/^action_(.+)$/ ) {
            push @actions, $1;
        }
    }

    return sort @actions;
}

sub actions_map {
    my ($self) = @_;

    return Text::Abbrev::abbrev($self->actions_list);
}

sub actions_string {
    my ($self) = @_;

    return join q{, }, $self->actions_list;
}

sub execute {
    my ( $self, $opts, $args ) = @_;

    my @request;
    if ( defined $args && ref $args eq 'ARRAY' ) {
        @request = @{ $args };
    }

    my $num = scalar @request;

    my $action;
    if ( $num == 1 ) {
        $action = $request[0];
    } elsif ( $num > 1 ) {
        die "You can only specify a single action\n";
    } else {
        die 'You must specify an action from: ' . $self->actions_string . "\n";
    }

    my %actions_map = $self->actions_map;
    if ( exists $actions_map{$action} ) {
        $action = $actions_map{$action};
    } else {
        die "Invalid action '$action', select from: " .
             $self->actions_string . "\n";
    }

    my $method = join q{_}, 'action', $action;

    return $self->$method();
}

no Moose::Role;

1;
__END__

=head1 NAME

PkgForge::Registry::App - A Moose role for applications which use the registry

=head1 VERSION

This documentation refers to PkgForge::Registry::App version 1.3.0

=head1 SYNOPSIS

      package PkgForge::App::Foo;

      use Moose;

      with 'PkgForge::Registry::App';

      sub action_add { ... }

      sub action_delete { ... }

      1;

      # and then via the command-line pkgforge application:

      % pkgforge foo add
      % pkgforge foo del

=head1 DESCRIPTION

This is a Moose role which is designed to simplify the creation of
Package Forge command-line applications that need to query or modify
the registry. It is intended to assist in doing two separate things
which are always required. The first is to add support for
sub-commands (actions) on top of the L<MooseX::App::Cmd> behaviour
already in place. The second is to give standardised access to the
Package Forge registry.

=head1 ATTRIBUTES

Any class which has this role applied will have the following attributes:

=over

=item configfile

An optional configuration file name which can be used to set the
values of the registry database attributes when a
L<PkgForge::Registry> object is instantiated using the
C<new_with_config> method. If not specified then the default file will
be used, if it exists, see L<PkgForge::Registry> for full
details. When used in conjunction with L<MooseX::App::Cmd::Command>
this becomes available as a command-line option.

=item registry

This holds the reference to the L<PkgForge::Registry> object itself.

=back

=head1 SUBROUTINES/METHODS

Any class which has this role applied will have the following methods:

=over

=item actions_list

This returns the list of all "action" methods in a class. An action
method is just a normal method with the name prefixed by
C<action_>. The prefix is stripped from the method names, e.g. if
there is a method named C<action_foo> then this method will return
C<foo>.

=item actions_map

This method takes the list of action methods from the C<actions_list>
method and converts it into a hash using L<Text::Abbrev>. The keys are
the unique abbreviations for each action name and the values are the
full length name.

=item actions_string

This method converts the list of actions into a comma-separated string
suitable for displaying to the user.

=item require_parameters(@attributes)

Normally all attributes would be marked as required where
necessary. When using this role some attributes may only be required
for certain actions. This method can be used to check the requirements
for each action. It is called to ensure that those attributes exist
and have values set, if any are not set it will die with a useful
error message.

=item execute

The L<App::Cmd::Command> class expects there to be a method named
C<execute> which does the actual work. This role extends this to allow
sub-commands (actions) and this is the method which decides what
action method should be executed. This allows the user to do something
like:

        pkgforge foo list

        pkgforge foo add

        pkgforge foo del

by creating a class named L<PkgForge::App::Foo>, which applies this
role, with methods named C<action_list>, C<action_add> and
C<action_delete>.

=back

=head1 CONFIGURATION AND ENVIRONMENT

This role adds an attribute, named C<configfile>, which can be used to
load a configuration file for the registry DB access. If you do not
specify this file name then the L<PkgForge::Registry> object will be
created using the default configuration file, if it exists and is
accessible. When used in conjunction with L<MooseX::App::Cmd::Command>
this becomes available as a command-line option.

It is not necessary to set all the attributes to successfully connect
to the database. The L<DBI> layer has support for using environment
variables for nearly all possible connection options, see L<DBD::Pg>
for full details.

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::ConfigFromFile>
and L<MooseX::Types>. This module is intended to work with
L<MooseX::App::Cmd::Command> but there is no direct dependency. It
also uses L<Text::Abbrev> to handle unique shortened names for
actions.

=head1 SEE ALSO

L<PkgForge>, pkgforge(1)

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




