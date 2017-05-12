package VCP::RevMapDB;

=head1 NAME

VCP::RevMapDB - Persistant storage for id -> (name, rev_id) maps

=head1 SYNOPSIS

    use base qw( VCP::RevMapDB );

=head1 DESCRIPTION

By default, most VCP::Dest::* drivers keep track of the relationship
between the id field assigned by the (original) VCP::Source::* driver
and the final name and rev_id (or whatever fields are important to it)
in the destination repository so that the previous_id fields, which
refer to the original id, may be resolved when backfilling or branching.

The VCP::*::revml drivers do not do this; they do not need to resolve id
fields.

The intent for this file is to serve as a base class so that individual
sites may write their own RevMapDB plugins to, for instance, store this
state in a RDBMS table.  This is not quite offered at this time; we need
to add an option to the appropriate VCP::Dest::* modules to allow the
appropriate RevMapDB file to be loaded.

To write your own RevMapDB file, see VCP::RevMapDB::sdbm.

=for test_script t/02revmapdb.t

=cut

$VERSION = 1 ;

use strict ;
require Carp;
use VCP::Logger qw( pr );

## TODO: Make the base class pluggable
use base "VCP::DB";

sub new {
    shift->SUPER::new( TableName => "rev_map", @_ );
}


sub get {
    my VCP::RevMapDB $self = shift;
    my ( $key ) = @_;

    my @v = $self->SUPER::get( $key );

    Carp::confess "vcp: no DB_File entry for ",
        join( ";", @$key ),
        "\n"
        unless @v;

    return @v;
}


sub set {
    my VCP::RevMapDB $self = shift;
    my ( $key ) = @_;

    pr "vcp: overwriting DB_File entry for ",
       join( ";", @$key ),
       ".  Stale vcp_state in ",
       $self->store_loc, "?\n"
      if $self->exists( $key );

    $self->SUPER::set( @_ );
}

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
