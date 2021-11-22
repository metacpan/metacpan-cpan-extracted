
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


use Carp::Clan qr/^PGObject\b/;
use List::MoreUtils qw(pairwise);
use Log::Any qw($log);
use Scalar::Util qw(reftype);


our $VERSION = '2.3.1';

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
    carp $log->warn( 'Using default registry' )
        unless $args{registry};
    croak $log->error( 'Missing dbtype arg' )
        unless $args{dbtype};
    croak $log->error( 'Missing apptype arg' )
        unless $args{apptype};
    delete $args{registry}           unless defined $args{registry};
    %args = ( %defaults, %args );
    croak $log->error( 'Registry does not exist yet' )
        unless exists $registry{ $args{registry} };
    croak $log->error( 'Type registered with different target' )
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
of which are required.  Note that at this time this is rarely needed.

=head2 unregister_type

=cut

sub unregister_type {
    my ( $self, %args ) = @_;
    croak $log->error( 'Missing registry' )
        unless $args{registry};
    croak $log->error( 'Missing dbtype arg' )
        unless $args{dbtype};
    croak $log->error( 'Registry does not exist yet' )
        unless exists $registry{ $args{registry} };
    carp $log->warn( 'Type not registered' )
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

    croak $log->error( "Missing dbstring arg" )
        unless exists $args{dbstring};
    return $self->deserializer( %args )->( $args{dbstring} );
}

=head2 deserializer

This returns a coderef to deserialize data from a db string. The coderef
should be called with a single argument: the argument that would be passed
as 'dbstring' into C<deserialize>. E.g.:

   my $deserializer = PGObject::Type::Registry->deserializer(dbtype => $type);
   my $value = $deserializer->($dbvalue);

Mandatory argument is dbtype.
The registry arg should be provided but if not, a warning will be issued and
'default' will be used.

This function returns the output of the C<from_db> method of the registered
class.

=cut

sub deserializer {
    my ( $self, %args ) = @_;
    my %defaults = ( registry => 'default' );
    carp $log->info( 'No registry specified, using default' )
        unless exists $args{registry};
    croak $log->error( "Missing dbtype arg" )
        unless $args{dbtype};
    %args = ( %defaults, %args );
    my $arraytype = 0;
    if ( $args{dbtype} =~ /^_/ ) {
        $args{dbtype} =~ s/^_//;
        $arraytype = 1;
    }

    return $args{_unmapped_undef} ? undef : sub { shift }
        unless $registry{ $args{registry} }->{ $args{dbtype} };

    if ($arraytype) {
        my $deserializer = $self->deserializer( %args );
        return sub { [ map { $deserializer->( $_ ) } @{ (shift) } ] };
    }

    my $clazz = $registry{ $args{registry} }->{ $args{dbtype} };
    my $from_db = $clazz->can('from_db');
    my $dbtype = $args{dbtype};
    return sub { $from_db->($clazz, (shift), $dbtype); }
}

=head2 rowhash_deserializer

This returns a coderef to deserialize data from a call to e.g.
C<fetchrow_arrayref>. The coderef should be called with a single argument:
the hash that holds the row values with the keys being the column names.

Mandatory argument is C<types>, which is either an arrayref or hashref.
In case of a hashref, the keys are the names of the columns to be expected
in the data hashrefs. The values are the types (same as the C<dbtype>
parameter of the C<deserialize> method). In case of an arrayref, an additional
argument C<columns> is required, containing the names of the columns in the
same order as C<types>.

The registry arg should be provided but if not, a warning will be issued and
'default' will be used.

This function returns the output of the C<from_db> method of the registered
class.

=cut

sub rowhash_deserializer {
    my ( $self, %args ) = @_;
    my %defaults = ( registry => 'default' );
    carp $log->warn( 'No registry specified, using default' )
        unless exists $args{registry};
    croak $log->error( 'No types specied' )
        unless exists $args{types};

    %args = ( %defaults, %args );
    my $types = $args{types};

    if (reftype $types eq 'ARRAY') {
        croak $log->error( 'No columns specified' )
            unless exists $args{columns};

        $types = { pairwise { $a => $b } @{$args{columns}}, @$types };
    }

    my %column_deserializers =
        map { $_ => $self->deserializer(dbtype          => $types->{$_},
                                        registry        => $args{registry},
                                        _unmapped_undef => 1)  } keys %$types;
    for (keys %column_deserializers) {
        if (not defined $column_deserializers{$_}) {
            delete $column_deserializers{$_}
        }
    }
    return sub {
        my $row = shift;

        for my $col (keys %column_deserializers) {
            $row->{$col} =
                $column_deserializers{$col}->( $row->{$col} );
        }
        return $row;
    }
}

=head1 INSPECTING A REGISTRY

Sometimes we need to see what types are registered.  To do this, we can
request a copy of the registry.

=head2 inspect($name)

$name is required.  If it does not exist an exception is thrown.

=cut

sub inspect {
    my ( $self, $name ) = @_;
    croak $log->error( 'Must specify a name' )
        unless $name;
    croak $log->error( 'Registry does not exist' )
        unless exists $registry{$name};
    return { %{ $registry{$name} } };
}

=head2 list()

Returns a list of existing registries.

=cut

sub list {
    return keys %registry;
}

=head1 COPYRIGHT AND LICENSE

COPYRIGHT (C) 2017-2021 The LedgerSMB Core Team

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
