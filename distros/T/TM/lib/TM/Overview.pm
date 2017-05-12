package TM::Overview;

=pod

=head1 NAME

TM::Overview - Topic Maps, Overview

=head1 INTRODUCTION

The TM suite of packages allows you to read and modify data organized according to the Topic Map
paradigm.  It includes some drivers to read TM content from files, such as LTM or AsTMa=, but also a
way to synchronize with MLDBM data files.

The core functionality is enhanced in several ways: bulk transfer of TM content into your
application, treating a set of maps as another map (mapsphere), map statistics and analysis, and
converting a map taxonomy into a tree. There is also a way to index an existing map.

The distribution also provides packages to handle 'virtual' topic maps, i.e. wrappers around other
resources which can be accessed via a TM interface and a set of backend technologies to make topic
maps persistent. There is also nascent support of a TMQL-like query language. There is also an
experimental TMDM-layer.

=head1 OVERVIEW

The set of classes and traits has evolved over several development stages and can be regarded as
failry stable.

=head2 TM Core

At the core sits the class L<TM>. This class implements a memory-based topic map store. With it, you
can instantiate maps, fill them with content and extract it again using direct access methods for
topic-like and association-like information. Its implementation paradigm is actually not TMDM, but
the much more low-level TMRM. According to that a map consists mostly of I<assertions> which are
light-weight associations. With these, associations, topic names and occurrences are implemented.
The topics themselves are collaps in this model to simple focal points carrying only subject locator
and subject indicator information.

The search functionality is quite minimalistic, mostly provided by the functions C<match_forall> and
C<match_exists>.

=head2 TM Traits

The core functionality is extensible in many, many different ways. To allow a developer precise
control over what he needs, these extensions are written as I<traits>, i.e. a set of methods which
can be added ad libitum to a TM object. Or, alternatively, you can create your own subclass of L<TM>
and mixin these traits as they suit you.

Here are some of the more interesting traits:

=over

=item L<TM::Synchronizable>

With it you can not only attach a map to an external resource (this is actually done by another
trait L<TM::ResourceAble>), but also have methods to I<synchronize in> (loading map content from the
resource into memory) and I<synchronize out> (saving map content to the resource).

Some resources are I<serializable>, i.e. the content is stored as a sequence of characters
(symbols).  Examples are LTM, AsTMa, XTM, etc. files. For each of these exists parsers, usually
tucked away in packages such as L<TM::Serializable::AsTMa>, L<TM::Serializeable::LTM>, etc.  Since
some formats are more popular, dedicated classes for these exist: L<TM::Materialized::AsTMa>,
L<TM::Materialized::LTM>, and so forth.

Some resources are not serializable, but they are still I<synchronizable>. One example of this is
L<TM::Synchronizable::MLDBM> which allows you to dump the whole map content into a MLDBM file.

=item L<TM::Analysis>, L<TM::Tree>

These packages allow you to compute some statistics of a map, but also to find the I<connected
island>, i.e. those parts of a map which are somehow linked together with associations. The tree
package can analyze a map in respect to an inherent tree structure. One example are family trees.

=item L<TM::MapSphere>

Since maps can store any information about the real world, they can also store information about
other maps. In this sense you can embed maps into other maps. Here this is done by having one topic
representing an embedded map. From then you can easily added meta-information about embedded maps,
such as authorship, access control, etc.

If you organize this hierarchically, then you end up with a tree of maps: The top-level map contains
various things, among them child maps. And each of these children can link to further maps. In a
sense this is a complete TM repository into which you can add maps (I<mount>) and remove complete
maps (I<umount>).

=item L<TM::Bulk>

Especially when building web frontends for TM servers, the communication events have to be
minimized.  With L<TM::Bulk> it is possible to learn a lot from a topic, instead of querying
numerous times. There is also a first lookup function for names.

=back

=head2 Indexing

Using a naive in-memory representation can be quite slow if you map gets big and the retrieval more
complex. To improve the performance instances of L<TM::Index> can be associated with the map. See
for the subclasses L<TM::Index::Match>, L<TM::Index::Characteristics>, L<TM::Index::Reify>.

[from v1.54]: There is now a trait L<TM::IndexAble> which you can attach to an existing map to
get index support (experimental).


=head2 TMDM

The low-level data structures are not exactly what most application developers would expect when
they come across Topic Maps. They are more familiar with the high-level TMDM. The package L<TM::DM>
tries to emulate this behaviour as closely as possible.

=head2 Tau Expressions

Still quite experimental (but cool) are Tau expressions which allow you to combine maps in various
ways, not just add them together for merging. One example would be the expression

  file:test.atm > file:test.xtm

which - when evaluated - will try to read AsTMa= content from the file C<test.atm> and will try to
save an XTM version of it into C<test.xtm>. More elaborate examples involve filtering:

  file:test.atm * urn:tau:statistics > io:stdout

That would take the map from C<test.atm> and would apply the converter C<urn:tau:statistics> to it
to compute the statistics of the map. The statistical information is represented as map as well; it
will then be copied to STDOUT (which is default anyway).

Tau expressions can also include TMQL queries and support any number of different formats (these are
pluggable at compile and at run time).

=head1 Workbench C<tm>

The distribution contains one 'binary' C<tm>. It is a command-line oriented interface to manage
topic map content. With it you can copy map, query them (soon) and transform them. The interface
also introduces one global store, a I<mapsphere> into which you can save one or more maps.

=head1 Tutorial: In-memory maps

@@@

=head1 Tutorial: Associating Resources

@@@

=head1 Tutorial: Adding Indices

@@@

=head1 Tutorial: Analyzing Maps

@@@

=head1 Tutorial: Managing MapSpheres

@@@

=head1 Tutorial: Tau Expressions

@@@

=head1 COPYRIGHT AND LICENSE

Copyright 200[3-6] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION  = 0.3;
our $REVISION = '$Id: Overview.pm,v 1.5 2006/12/13 10:46:58 rho Exp $';

1;
