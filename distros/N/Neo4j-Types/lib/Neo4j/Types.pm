use strict;
use warnings;

package Neo4j::Types;
# ABSTRACT: Common Neo4j type system
$Neo4j::Types::VERSION = '1.00';

use Neo4j::Types::Node;
use Neo4j::Types::Path;
use Neo4j::Types::Point;
use Neo4j::Types::Relationship;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Types - Common Neo4j type system

=head1 VERSION

version 1.00

=head1 SYNOPSIS

 # direct use
 $node = bless $data, 'Neo4j::Types::Node';
 
 # indirect use
 $node = bless $data, 'Local::Node';
 
 package Local::Node;
 use parent 'Neo4j::Types::Node';
 # override methods as required

=head1 DESCRIPTION

The packages in this distribution offer a Neo4j type system for Perl.
Other distributions for the Neo4j ecosystem such as L<Neo4j::Bolt>
and L<Neo4j::Driver> can (if they so choose) use these packages
either directly or indirectly.

If several such distributions share the same representation of Neo4j
values, sharing data between distributions becomes more efficient and
users may have an easier time alternating between them.

Packages in this distribution primarily define methods. They do not
currently make any particular assumptions about their internal data
structures. This distribution offers default implementations of the
methods it defines; these are designed to work with L<Neo4j::Bolt>
data structures. But inheritors (such as C<Local::Node> in the
synopsis example) are free to use any data structure they like,
provided they override methods as required to not change the API.

The methods defined by this distribution are loosely modelled
on the Neo4j Driver API. They don't match that API precisely
because the official Neo4j drivers don't always use the exact
same method names for their functionality, and the
L<Neo4j Driver API Spec|https://7687.org/driver_api/driver-api-specification.html>
currently doesn't discuss these methods.

The module L<Neo4j::Types> itself currently only contains
documentation, but you can C<use> it as a shortcut to make all
modules that are included in this distribution available to you.

=head1 CYPHER TYPES

The Neo4j Cypher Manual mentions a variety of types. This section
discusses typical ways to implement these in Perl.

=head2 Composite types

Composite types are:

=over

=item * List

=item * Map (also known as Dictionary)

=back

In Perl, these types match simple unblessed array and hash
references very nicely.

=head2 Node, Relationship, Path

Neo4j structural types may be represented as:

=over

=item * L<Neo4j::Types::Node>

=item * L<Neo4j::Types::Relationship>

=item * L<Neo4j::Types::Path>

=back

=head2 Scalar types

Values of the following types can in principle be stored as a Perl
scalar. However, Perl scalars by themselves cannot cleanly separate
between all of these types. This can make it difficult to convert
scalars back to Cypher types (for example for the use in Cypher
statements parameters).

=over

=item Number (Integer or Float)

Both Neo4j and Perl internally distinguish between integer numbers
and floating-point numbers. Neo4j stores these as Java C<long> and
C<double>, which both are signed 64-bit types. In Perl, their
precision is whatever was used by the C compiler to build your
Perl executable (usually 64-bit types as well on modern systems).

Both Neo4j and Perl will automatically convert integers to floats
to calculate an expression if necessary (like for C<1 + 0.5>), so
the distinction between integers and floats often doesn't matter.
However, integers and floats are both just scalars in Perl, which
may make it difficult to create a float with an integer value in
Neo4j (for example, trying to store C<$a = 2.0 + 1> as a property
may result in the integer C<3> being stored in Neo4j).

L<perlnumber> explains further details on type conversions in Perl.
In particular, Perl will also try to automatically convert between
strings and numbers, but Neo4j will not. This may have unintended
consequences, as the following example demonstrates.

 $id = get_id_from_node($node);  # returns an integer
 say "The ID is $id.";           # silently turns $id into a string
 $node = get_node_by_id($id);    # fails: ID must be integer

This latter situation may be solved by using unary coercions.

 $string = "$number";
 $number = 0 + $string;

In the future, the L<Neo4j::Types> distribution might be extended
to offer ways to better handle the issues described in this section.

=item String

Perl scalars are a good match for Neo4j strings. However, in some
situations, scalar strings may easily be confused with numbers or
byte arrays in Perl.

Neo4j strings are always encoded in UTF-8. Perl supports this as
well (though string scalars that only contain ASCII are usually
not treated as UTF-8 internally for efficiency reasons).

=item Boolean

Perl does not have a native boolean data type. It's trivial to
map from Cypher booleans to truthy or non-truthy Perl scalars,
but the reverse is difficult without additional information.

There are a multitude of modules on CPAN that try to solve
this problem, including L<boolean>, L<Types::Bool>, and
L<Types::Serialiser>. Among them, L<JSON::PP::Boolean> has
the advantage that it has long been in Perl CORE.

=item Null

The Cypher C<null> value can be neatly implemented as Perl C<undef>.

=item Byte array

Byte arrays are not actually Cypher types, but still have some
limited support as pass-through values in Neo4j. In Perl, byte
arrays are most efficiently represented as string scalars with
their C<UTF8> flag turned off (though there may be some gotchas;
see L<perlguts/"Working with SVs"> for details).

However, it usually isn't possible to determine whether such a
scalar actually is supposed to be a byte array or a string; see
L<perlguts/"How can I recognise a UTF-8 string?">. In the future,
the L<Neo4j::Types> distribution might be extended to offer ways
to handle this.

=back

=head2 Spatial types

The only spatial type currently offered by Neo4j is the point.
It may be represented as L<Neo4j::Types::Point>.

It might be possible to (crudely) represent other spatial types by
using a list of points plus external metadata, or in a Neo4j graph
by treating the graph itself as a spatial representation.

The coordinate reference systems of spatial points in Neo4j are
currently severely constrained. There is no way to tag points with
the CRS they actually use, and for geographic coordinates (lat/lon),
only a single, subtly non-standard CRS is even supported. For uses
that don't require the spatial functions that Neo4j offers, it might
be best to eschew the point type completely and store coordinate
pairs as a simple list in the Neo4j database instead.

=head2 Temporal types

Cypher temporal types include: Date, Time, LocalTime, DateTime,
LocalDateTime, and Duration.

This distribution currently does not handle dates, times, or
durations. It is suggested to use the existing packages L<DateTime>
and L<DateTime::Duration>.

=head1 SEE ALSO

=over

=item * L<Neo4j::Bolt/"Return Types">

=item * L<Neo4j::Driver::Record/"get">

=item * L<REST::Neo4p::Entity>

=item * L<"Values and types" in Neo4j Cypher Manual|https://neo4j.com/docs/cypher-manual/current/syntax/values/>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
