
=head1 NAME

PGObject - A toolkit integrating intelligent PostgreSQL dbs into Perl objects

=cut

package PGObject;

use strict;
use warnings;

use Carp::Clan qr/^PGObject\b/;
use Log::Any qw($log);
use Memoize;


use PGObject::Type::Registry;

=head1 VERSION

Version 2.3.2

=cut

our $VERSION = '2.3.2';

=head1 SYNPOSIS

To use without caching:

  use PGObject;

To use with caching:

  use PGObject ':cache';

To get basic info from a function

  my $f_info = PGObject->function_info(
      dbh        =>  $dbh,
      funcname   =>  $funcname,
      funcschema =>  'public',
  );

To get info about a function, filtered by first argument type

  my $f_info = PGObject->function_info(
      dbh        =>  $dbh,
      funcname   =>  $funcname,
      funcschema =>  'public',
      funcprefix =>  'test__',
      objtype    =>  'invoice',
      objschema  =>  'public',
  );

To call a function with enumerated arguments

  my @results = PGObject->call_procedure(
      dbh          =>  $dbh,
      funcname     => $funcname,
      funcprefix =>  'test__',
      funcschema   => $funcname,
      args         => [$arg1, $arg2, $arg3],
  );

To do the same with a running total

  my @results = PGObject->call_procedure(
      dbh           =>  $dbh,
      funcname      => $funcname,
      funcschema    => $funcname,
      args          => [$arg1, $arg2, $arg3],
      running_funcs => [{agg => 'sum(amount)', alias => 'running_total'}],
  );

=cut

sub import {
    my @directives = @_;
    memoize 'function_info' if grep { $_ eq ':cache' } @directives;
    PGObject::Type::Registry->new_registry($_)
        for grep { $_ !~ /^\:/; } @directives;
}

=head1 DESCRIPTION

PGObject contains the base routines for object management using discoverable
stored procedures in PostgreSQL databases.  This module contains only common
functionality and support structures, and low-level API's.  Most developers will
want to use more functional modules which add to these functions.

The overall approach here is to provide the basics for a toolkit that other
modules can extend.  This is thus intended to be a component for building
integration between PostgreSQL user defined functions and Perl objects.

Because decisions such as state handling are largely outside of the scope of
this module, this module itself does not do any significant state handling.
Database handles (using DBD::Pg 2.0 or later) must be passed in on every call.
This decision was made in order to allow for diversity in this area, with the
idea that wrapper classes would be written to implement this.

=head1 FUNCTIONS

=head2 clear_info_cache

This function clears the info cache if this was loaded with caching enabled.

The cache is also automatically cleared when a function that was run could not
be found (this could be caused by updating the db).

=cut

sub clear_info_cache {
    local ($@);
    eval { Memoize::flush_cache('function_info') };
}

=head2 function_info(%args)

Arguments:

=over

=item dbh (required)

Database handle

=item funcname (required)

function name

=item funcschema (optional, default 'public')

function schema

=item funcprefix (optiona, default '')

Prefix for the function.  This can be useful for separating functions by class.

=item argtype1 (optional)

Name of first argument type.  If not provided, does not filter on this criteria.

=item argschema (optional)

Name of first argument type's schema.  If not provided defaults to 'public'

=back

This function looks up basic mapping information for a function.  If more than
one function is found, an exception is raised.  This function is primarily
intended to be used by packages which extend this one, in order to accomplish
stored procedure to object mapping.

Return data is a hashref containing the following elements:

=over

=item args

This is an arrayref of hashrefs, each of which contains 'name' and 'type'

=item name

The name of the function

=item num_args

The number of arguments

=back

=cut

sub function_info {
    my ( $self, %args ) = @_;
    $args{funcschema} ||= 'public';
    $args{funcprefix} ||= '';
    $args{funcname} = $args{funcprefix} . $args{funcname};
    $args{argschema} ||= 'public';

    my $dbh = $args{dbh} || croak $log->error( 'No dbh provided' );

    my $query = qq|
        SELECT proname, pronargs, proargnames,
               string_to_array(array_to_string(proargtypes::regtype[], ' '),
                               ' ') as argtypes
          FROM pg_proc
          JOIN pg_namespace pgn ON pgn.oid = pronamespace
         WHERE proname = ? AND nspname = ?
    |;
    my @queryargs = ( $args{funcname}, $args{funcschema} );
    if ( $args{argtype1} ) {
        $query .= qq|
               AND (proargtypes::int[])[0] IN (select t.oid
                                                 from pg_type t
                                                 join pg_namespace n
                                                      ON n.oid = typnamespace
                                                where typname = ?
                                                      AND n.nspname = ?
       )|;
        push @queryargs, $args{argtype1};
        push @queryargs, $args{argschema};
    }

    my $sth = $dbh->prepare($query) || die $!;
    $sth->execute(@queryargs) || die $dbh->errstr . ": " . $query;
    my $rows = $sth->rows;
    if ($rows > 1) {
        if ($args{argtype1}) {
            croak $log->fatalf(
                'Ambiguous criteria discovering function %s.%s (with first argument type %s)',
                $args{funcschema}, $args{funcname}, $args{argtype1}
                );
        }
        else {
            croak $log->fatalf(
                'Ambiguous criteria discovering function %s.%s',
                $args{funcschema}, $args{funcname}
                );
        }
    }
    elsif ($rows == 0) {
        croak $log->fatalf( 'No such function: %s.%s',
                            $args{funcschema}, $args{funcname} );
    }
    my $ref = $sth->fetchrow_hashref('NAME_lc');

    my $f_args;
    for my $n ( @{ $ref->{proargnames} } ) {
        push @$f_args, { name => $n, type => shift @{ $ref->{argtypes} } };
    }

    return {
        name     => $ref->{proname},
        num_args => $ref->{pronargs},
        args     => $f_args,
    };

}

=head2 call_procedure(%args)

Arguments:

=over

=item funcname

The function name

=item funcschema

The schema in which the function resides

=item funcprefix (optiona, default '')

Prefix for the function.  This can be useful for separating functions by class.

=item args

This is an arrayref.  Each item is either a literal value, an arrayref, or a
hashref of extended information.  In the hashref case, the type key specifies
the string to use to cast the type in, and value is the value.

=item orderby

The list (arrayref) of columns on output for ordering.

=item running_funcs

An arrayref of running windowed aggregates.  Each contains two keys, namely 'agg' for the aggregate and 'alias' for the function name.

These are aggregates, each one has appended 'OVER (ROWS UNBOUNDED PRECEDING)'
to it.

=item registry

This is the name of the registry used for type conversion.  It can be omitted
and defaults to 'default.'  Note that use of a non-standard registry currently
does *not* merge changes from the default registry, so you need to reregister
types in non-default registries when you create them.

Please note, these aggregates are not intended to be user-supplied.  Please only
allow whitelisted values here or construct in a tested framework elsewhere.
Because of the syntax here, there is no sql injection prevention possible at
the framework level for this parameter.

=back

=cut

sub call_procedure {
    my ( $self, %args ) = @_;
    local $@;
    $args{funcschema} ||= 'public';
    $args{funcprefix} ||= '';
    $args{funcname} = $args{funcprefix} . $args{funcname};
    $args{registry} ||= 'default';

    my $dbh = $args{dbh};
    croak $log->error( "No database handle provided" )
        unless $dbh;
    croak $log->error( "dbh not a database handle" )
        unless eval { $dbh->isa('DBI::db') };

    my $wf_string = '';

    $wf_string = join ', ', map {
              $_->{agg}
            . ' OVER (ROWS UNBOUNDED PRECEDING) AS '
            . $_->{alias}
    } @{ $args{running_funcs} } if $args{running_funcs};
    $wf_string = ', ' . $wf_string if $wf_string;

    my @qargs = map {
        my $arg = $_;
        local ($@);
        $arg = $arg->to_db          if eval { $arg->can('to_db') };
        $arg = $arg->pgobject_to_db if eval { $arg->can('pgobject_to_db') };
        $arg;
    } @{ $args{args} };

    my $argstr = join ', ', map {
        ( ref $_ and eval { $_->{cast} } ) ? "?::$_->{cast}" : '?';
    } @{ $args{args} };

    my $order = '';
    if ( $args{orderby} ) {
        $order = join(
            ', ',
            map {
                my $dir = undef;
                if (s/\s+(ASC|DESC)\s*$//i) {
                    $dir = $1;
                }
                defined $dir
                    ? $dbh->quote_identifier($_) . " $dir"
                    : $dbh->quote_identifier($_);
            } @{ $args{orderby} }
        );
    }
    my $query = qq|
           SELECT * $wf_string
             FROM |
        . $dbh->quote_identifier( $args{funcschema} ) . '.'
        . $dbh->quote_identifier( $args{funcname} )
        . qq|($argstr) |;
    if ($order) {
        $query .= qq|
         ORDER BY $order |;
    }

    my $sth = $dbh->prepare($query) || die $!;

    my $place = 1;

    foreach my $carg (@qargs) {
        if ( ref($carg) =~ /HASH/ ) {
            $sth->bind_param( $place, $carg->{value},
                { pg_type => $carg->{type} } );
        }
        else {

            # This is used to support arrays of db-aware types.  Long-run
            # I think we should merge bytea support into this framework. --CT
            if ( ref($carg) =~ /ARRAY/ ) {
                local ($@);
                if ( eval { $carg->[0]->can('to_db') } ) {
                    for my $ref (@$carg) {
                        $ref = $ref->to_db;
                    }
                }
            }

            $sth->bind_param( $place, $carg );
        }
        ++$place;
    }

    $sth->execute() || die $dbh->errstr . ": " . $query;

    clear_info_cache() if $dbh->state eq '42883';    # (No Such Function)

    my @rows = ();
    my $row_deserializer =
        PGObject::Type::Registry->rowhash_deserializer(
            registry => $args{registry},
            types    => $sth->{pg_type},
            columns  => $sth->{NAME_lc},
        );
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @rows, $row_deserializer->( $row );
    }
    return @rows;
}

=head2 new_registry($registry_name)

Creates a new registry if it does not exist.  This is useful when segments of
an application must override existing type mappings.

This is deprecated and throws a warning.

Use PGObject::Type::Registry->new_registry($registry_name) instead.

This no longer returns anything of significance.

=cut

sub new_registry {
    my ( $self, $registry_name ) = @_;
    carp $log->warn( "Deprecated use of PGObject->new_registry()" );
    PGObject::Type::Registry->new_registry($registry_name);
}

=head2 register_type(pgtype => $tname, registry => $regname, perl_class => $pm)

DEPRECATED

Registers a type as a class.  This means that when an attribute of type $pg_type
is returned, that PGObject will automatically return whatever
$perl_class->from_db returns.  This allows you to have a db-specific constructor
for such types.

The registry argument is optional and defaults to 'default'

If the registry does not exist, an error is raised.  if the pg_type is already
registered to a different type, this returns 0.  Returns 1 on success.

Use PGObject::Type::Registry->register_type() instead.

=cut

sub register_type {
    carp $log->warn( 'Use of deprecated method register_type of PGObject module' );
    my ( $self, %args ) = @_;

    PGObject::Type::Registry->register_type(
        registry => $args{registry},
        dbtype   => $args{pg_type},
        apptype  => $args{perl_class}
    );
    return 1;
}

=head2 unregister_type(pgtype => $tname, registry => $regname)

Deprecated.

Tries to unregister the type.  If the type does not exist, returns 0, otherwise
returns 1.  This is mostly useful for when a specific type must make sure it has
the slot.  This is rarely desirable.  It is usually better to use a subregistry
instead.

=cut

sub unregister_type {
    carp $log->warn( 'Use of deprecated method unregister_type of PGObject' );
    my ( $self, %args ) = @_;

    $args{registry} ||= 'default';
    PGObject::Type::Registry->unregister_type(
        registry => $args{registry},
        dbtype   => $args{pg_type}
    );
}

=head1 WRITING PGOBJECT-AWARE HELPER CLASSES

One of the powerful features of PGObject is the ability to declare methods in
types which can be dynamically detected and used to serialize data for query
purposes. Objects which contain a pgobject_to_db() or a to_db() method, that
method will be called and the return value used in place of the object.  This
can allow arbitrary types to serialize themselves in arbitrary ways.

For example a date object could be set up with such a method which would export
a string in yyyy-mm-dd format.  An object could look up its own definition and
return something like :

   { cast => 'dbtypename', value => '("A","List","Of","Properties")'}

If a scalar is returned that is used as the serialized value.  If a hashref is
returned, it must follow the type format:

  type  => variable binding type,
  cast  => db cast type
  value => literal representation of type, as intelligible by DBD::Pg

=head2 REQUIRED INTERFACES

Registered types MUST implement a $class->from_db function accepts the string
from the database as its only argument, and returns the object of the desired
type.

Any type MAY present an $object->to_db() interface, requiring no arguments, and returning a valid value.  These can be hashrefs as specified above, arrayrefs
(converted to PostgreSQL arrays by DBD::Pg) or scalar text values.

=head2 UNDERSTANDING THE REGISTRY SYSTEM

Note that 2.0 moves the registry to a service module which handles both
registry and deserialization of database types.  This is intended to be both
cleaner and more flexible than the embedded system in 1.x.

The registry system allows Perl classes to "claim" PostgreSQL types within a
certain domain.  For example, if I want to ensure that all numeric types are
turned into Math::BigFloat objects, I can build a wrapper class with appropriate
interfaces, but PGObject won't know to convert numeric types to this new class,
so this is what registration is for.

By default, these mappings are fully global.  Once a class claims a type, unless
another type goes through the trouble of unregisterign the first type and making
sure it gets the authoritative spot, all items of that type get turned into the
appropriate Perl object types.  While this is sufficient for the vast number of
applications, however, there may be cases where names conflict across schemas or
the like.  To address this application components may create their own
registries.  Each registry is fully global, but application components can
specify non-standard registries when calling procedures, and PGObject will use
only those components registered on the non-standard registry when checking rows
before output.

=head3 Backwards Incompatibilities from 1.x

Deserialization occurs in a context which specifies a registry.  In 1.x there
were no concerns about default mappings but now this triggers a warning.  The
most basic and frequently used portions of this have been kept but return values
for registering types has changed.  We no longer provide a return variable but
throw an exception if the type cannot be safely registered.

This follows a philosophy of throwing exceptions when guarantees cannot be met.

We now throw warnings when the default registry is used.

Longer-run, deserializers should use the PGObject::Type::Registry interface
directly.

=head1 WRITING TOP-HALF OBJECT FRAMEWORKS FOR PGOBJECT

PGObject is intended to be the database-facing side of a framework for objects.
The intended structure is for three tiers of logic:

=over

=item  Database facing, low-level API's

=item  Object management modules

=item  Application handlers with things like database connection management.

=back

By top half, we are referring to the second tier.  The third tier exists in the
client application.

The PGObject module provides only low-level API's in that first tier.  The job
of this module is to provide database function information to the upper level
modules.

We do not supply type information, If your top-level module needs this, please
check out https://code.google.com/p/typeutils/ which could then be used via our
function mapping APIs here.

=head2 Safely Handling Memoization of Catalog Lookups

It is important to remember, when writing PGObject top half frameworks that the
catalog lookups may be memoized and may come back as a data structure.  This
means that changes to the structures returned from get_function_info() in this
module and similar functions in other catalog-bound modules may not be safe to
modify in arbitrary ways.  Therefore we recommend that the return values from
catalog-lookup functions are treated as immutable.

Normalizing output is safe provided there are no conflicts between naming
conventions.  This is usually true since different naming conventions would
interfere withmapping.  However, there could be cases where it is not true, for
example, where two different mapping modules agree on a subset of normalization
conventions but differ on some details.  The two might safely handle the same
conventions but normalize differently resulting in conflicts of both were used.

=head1 A BRIEF GUIDE TO THE NAMESPACE LAYOUT

Most names underneath PGObject can be assumed to be top-half modules and modules
under those can be generally assumed to be variants on those.  There are,
however, a few reserved names:

=over

=item ::Debug is reserved for debugging information.  For example, functions
which retrieve sources of functions, or grab diagnostics, or the like would go
here.

=item ::Test is reserved for test framework extensions applible only here

=item ::Type is reserved for PG aware type classes.

For example, one might have PGObject::Type::BigFloat for a Math::Bigfloat
wrapper, or PGObject::Type::DateTime for a DateTime wrapper.

=item ::Util is reserved for utility functions and classes.

=back

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject


You can also look for information at:

=over

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject>

=item * MetaCPAN

L<https://metacpan.org/dist/PGObject>

=back

=head1 ACKNOWLEDGEMENTS

This code has been loosely based on code written for the LedgerSMB open source
accounting and ERP project.  While that software uses the GNU GPL v2 or later,
this is my own reimplementation, based on my original contributions to that
project alone, and it differs in significant ways.   This being said, without
LedgerSMB, this module wouldn't exist, and without the lessons learned there,
and the great people who have helped make this possible, this framework would
not be half of what it is today.


=head1 SEE ALSO

=over

=item PGObject::Simple - Simple mapping of object properties to stored proc args

=item PGObject::Simple::Role - Moose-enabled wrapper for PGObject::Simple

=back

=head1 COPYRIGHT

  COPYRIGHT (C) 2013-2014 Chris Travers
  COPYRIGHT (C) 2014-2021 The LedgerSMB Core Team

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

=head1 LICENSE

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
