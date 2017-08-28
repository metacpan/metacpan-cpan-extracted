
=head1 NAME

PGObject::Type::Registry - Registration of types for handing db types

=head1 SYNOPSIS

  PGObject::Type::Registry->add_registry('myapp'); # required

  PGObject::Type::Registry->register_type(
     registry => 'myapp', dbtype => 'int4',
     apptype => 'PGObject::Type::BigFloat'
  );

  # to get back a type:
  my $number = PGObject::Type::Registry->deserialize(
     registry => 'myapp', dbtype => 'int4',
     dbstring => '1023'
  );

  # To get registry data:
  my %registry = PGObject::Type::Registry->inspect(registry => 'myapp');

=cut

package PGObject::Type::Registry;
use strict;
use warnings;
use Try::Tiny;
use Carp;

our $VERSION = 1.000000;

my %registry = ( default => {} );

=head1 DESCRIPTION

The PGObject type registry stores data for serialization and deserialization
relating to the database.

=head1 USE

Generally we like to separate applications into their own registries so that
different libraries can be used in a more harmonious way.

=head1 CREATING A REGISTRY

You must create a registry before using it.  This is there to ensure that we
make sure that subtle problems are avoided and strings returned when serialized
types expected.  This is idempotent and repeat calls are safe. There is no
abiltiy to remove an existing registry though you can loop through and remove
the existing registrations.

=head2 new_registry(name)

=cut

sub new_registry {
    my ( $self, $name ) = @_;
    if ( not exists $registry{$name} ) {
        $registry{$name} = {};
    }
}

=head1 REGISTERING A TYPE

=head2 register_type

Args:

    registry => 'default', #warning thrown if not specified
    dbtype => [required], #exception thrown if not specified
    apptype => [required], #exception thrown if not specified

Use:

This registers a type for use by PGObject.  PGObject calls with the same
registry key will serialize to this type, using the from_db method provided.

from_db will be provided two arguments.  The first is the string from the
database and the second is the type provided.  The second argument is optional
and passed along for the db interface class's use.

A warning is thrown if no

=cut

sub register_type {
    my ( $self, %args ) = @_;
    my %defaults = ( registry => 'default' );
    carp 'Using default registry'    unless $args{registry};
    croak 'Must provide dbtype arg'  unless $args{dbtype};
    croak 'Must provide apptype arg' unless $args{apptype};
    delete $args{registry}           unless defined $args{registry};
    %args = ( %defaults, %args );
    croak 'Registry does not exist yet'
        unless exists $registry{ $args{registry} };
    croak 'Type registered with different target'
        if exists $registry{ $args{registry} }->{ $args{dbtype} }
        and $registry{ $args{registry} }->{ $args{dbtype} } ne $args{apptype};
    $args{apptype} =~ /^(.*)::(\w*)$/;
    my ( $parent, $final ) = ( $1, $2 );
    $parent ||= '';
    $final  ||= $args{apptype};
    {
        no strict 'refs';
        $parent = "${parent}::" if $parent;
        croak "apptype not yet loaded ($args{apptype})"
            unless exists ${"::${parent}"}{"${final}::"};
        croak 'apptype does not have from_db function'
            unless $args{apptype}->can('from_db');
    }
    %args = ( %defaults, %args );
    $registry{ $args{registry} }->{ $args{dbtype} } = $args{apptype};
}

=head1 UNREGISTERING A TYPE

To unregister a type, you provide the dbtype and registry information, both
of which are required.  Note that at that this is rarely needed.

=head2 unregister_type

=cut

sub unregister_type {
    my ( $self, %args ) = @_;
    croak 'Must provide registry'   unless $args{registry};
    croak 'Must provide dbtype arg' unless $args{dbtype};
    croak 'Registry does not exist yet'
        unless exists $registry{ $args{registry} };
    croak 'Type not registered'
        unless $registry{ $args{registry} }->{ $args{dbtype} };
    delete $registry{ $args{registry} }->{ $args{dbtype} };
}

=head1 DESERIALIZING A VALUE

=head2 deserialize

This function deserializes a data from a db string.

Mandatory args are dbtype and dbstring
The registry arg should be provided but if not, a warning will be issued and
'default' will be used.

This function returns the output of the from_db method.

=cut

sub deserialize {
    my ( $self, %args ) = @_;
    my %defaults = ( registry => 'default' );
    carp 'No registry specified, using default' unless exists $args{registry};
    croak "Must specify dbtype arg"             unless $args{dbtype};
    croak "Must specify dbstring arg"           unless exists $args{dbstring};
    %args = ( %defaults, %args );
    my $arraytype = 0;
    if ( $args{dbtype} =~ /^_/ ) {
        $args{dbtype} =~ s/^_//;
        $arraytype = 1;
    }
    no strict 'refs';
    return $args{dbstring}
        unless $registry{ $args{registry} }->{ $args{dbtype} };

    return [ map { $self->deserialize( %args, dbstring => $_ ) }
            @{ $args{dbstring} } ]
        if $arraytype;

    return "$registry{$args{registry}}->{$args{dbtype}}"->can('from_db')->(
        $registry{ $args{registry} }->{ $args{dbtype} },
        $args{dbstring}, $args{dbtype}
    );
}

=head1 INSPECTING A REGISTRY

Sometimes we need to see what types are registered.  To do this, we can
request a copy of the registry.

=head2 inspect($name)

$name is required.  If it does not exist an exception is thrown.

=cut

sub inspect {
    my ( $self, $name ) = @_;
    croak 'Must specify a name' unless $name;
    croak 'Registry does not exist' unless exists $registry{$name};
    return { %{ $registry{$name} } };
}

=head2 list()

Returns a list of existing registries.

=cut

sub list {
    return keys %registry;
}

=head1 COPYRIGHT AND LICENSE

COPYRIGHT (C) 2017 The LedgerSMB Core Team

Redistribution and use in source and compiled forms with or without
modification, are permitted provided that the following conditions are met:

=over

=item

Redistributions of source code must retain the above
copyright notice, this list of conditions and the following disclaimer as the
first lines of this file unmodified.

=item

Redistributions in compiled form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
source code, documentation, and/or other materials provided with the
distribution.

=back

THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
