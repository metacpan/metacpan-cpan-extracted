
=head1 NAME

Tangram::Sucks - what there is to be improved in Tangram

=head1 DESCRIPTION

Tangram has taken a concept very familiar to programmers in Java land
to its logical completion.

This document is an attempt by the coders of Tangram to summarise the
major problems that are inherant in the design, describe cases for
which the Tangram metaphor does not work well, and list long standing
TO-DO items.

=head2 DESIGN CAVEATS

=over

=item B<query language does not cover all SQL expressions>

Whilst there is no underlying fault with the query object metaphor
I<per se>, there are currently lots of queries that cannot be
expressed in current versions of Tangram, and adding new parts to the
language is not easy.

=item B<some loss of encapsulation with queries>

It could be said this is not a problem.  After all, adding properties
to a schema of an object is akin to declaring them as "public".

Some people banter on about I<data access patterns>, which the Tangram
schema represents.  But OO terms like that are usually treated as
buzzwords anyway.

=back

=head2 HARD PROBLEMS

=over

=item B<partial column select>

This optimisation has some serious dangers associated with it.

It could either be

=item B<no support for SQL UPDATE>

It may be possible to write a version of C<$storage-E<gt>select()>
that does this, which would look something like:

  $storage->update
      ( $r_object,
        set => [ $r_object->{bar} == $r_object->{baz} + 2 ],
        filter => ($r_object->{frop} != undef)
      );

=item B<no explicit support for re-orgs>

The situation where you have a large amount of schema reshaping to do,
with a complex enough data structure can turn into a fairly difficult
problem.

It is possible to have two Tangram stores with different schema and
simply load objects from one and put them in the other - however the
on-demand autoloading combined with the automatic insertion of unknown
objects will result in the entire database being loaded into core if
it is sufficiently interlinked.

=item B<replace SQL expression core>

The whole SQL expression core needs to be replaced with a SQL
abstraction module that is a little better planned.  For instance,
there should be placeholders used in a lot more places where the code
just sticks in an integer etc.

=item B<support for `large' collections>

Where it is impractical or undesirable to load all of a collection
into memory, when you are adding a member and then updating the
container, it should be possible to do this without loading the
entire collection into memory.

This could actually be achieved with a new Tangram::Type.

=back

=head2 MISSING FEATURES

=over

=item B<concise query expressions>

For simple selects, the query syntax is too long.  Getting remote
objects should take less code.

=item B<non-ID joins>

We can't join on anything but "ID" values

=item B<tables with no primary key>

We can't map tables unless they have a primary key, and it is called
"id" (or, at least, the same name as the rest of the schema).

=item B<tables with multi-column primary keys>

We can't map tables when they have multiple primary keys.  Well, you
can, but only if you make a view with an ID column which is
functionally derived from the multi-part keys.  But that sucks.

=item B<tables with auto_increment keys>

These suck, but Tangram could still support them without requiring
schema hacks.

=item B<tables without a `type' column>

The 'type' column is unneeded for base tables which do not have
sub-classes.

=item B<tables with custom `type' columns>

For mapping schemata where some clever person has invented their own
special way of representing types using discrete column values.

=item B<tables with implicit (presence) `type' columns>

It should be possible to infer the type value based on knowledge of
the schema, and the tables which have rows.

=item B<fully symmetric relationships>

back-refs are read-only.

=item B<bulk inserts>

Inserting lots of similar objects should be more efficient.  Right now
it generates a new DBI statement handler for each object.

=item B<`empty subclass' schema support>

You should not need to explicitly add new classes to a schema if a
superclass of them is already in the schema.

=item B<warn about column redefinitions>

Defining a column twice should be an error.  Reported by Mark
Lawrence.

=back


=cut

