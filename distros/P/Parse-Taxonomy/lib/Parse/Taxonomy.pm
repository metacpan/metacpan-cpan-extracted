package Parse::Taxonomy;
use strict;
use Carp;
use Scalar::Util qw( reftype );
our $VERSION = '0.24';

=head1 NAME

Parse::Taxonomy - Validate hierarchical data stored in CSV format

=head1 VERSION

This document refers to version 0.24 of Parse::Taxonomy.  This version was
released April 09 2016.

=head1 SYNOPSIS

    use Parse::Taxonomy;

=head1 DESCRIPTION

This module is the base class for the Parse-Taxonomy extension to the
Perl 5 programming language.  You will not instantiate objects of this class;
rather, you will instantiate objects of subclasses, of which
Parse::Taxonomy::MaterializedPath and Parse::Taxonomy::AdjacentList are the first.

B<This is an BETA release.>  The documented interfaces are expected to remain
stable but are not guaranteed to remain so.

=head2 Taxonomy: definition

For the purpose of this library, a B<taxonomy> is defined as a tree-like data
structure with a root node, zero or more branch (child) nodes, and one or more
leaf nodes.  The root node and each branch node must have at least one child
node, but leaf nodes have no child nodes.  The number of branches
between a leaf node and the root node is variable.

B<Diagram 1:>

                               Root
                                |
                  ----------------------------------------------------
                  |                            |            |        |
               Branch                       Branch       Branch     Leaf
                  |                            |            |
       -------------------------         ------------       |
       |                       |         |          |       |
    Branch                  Branch     Leaf       Leaf   Branch
       |                       |                            |
       |                 ------------                       |
       |                 |          |                       |
     Leaf              Leaf       Leaf                    Leaf

=head2 Taxonomy File:  definition

For the purpose of this module, a B<taxonomy file> is a CSV file in which (a)
certain columns hold data from which the position of each record within the
taxonomy can be derived; and (b) each node in the tree (with the possible
exception of the root node) is uniquely represented by a record within the
file.

=head3 CSV

B<"CSV">, strictly speaking, refers to B<comma-separated values>:

    path,nationality,gender,age,income,id_no

For the purpose of this module, however, the column separators in a taxonomy
file may be any user-specified character handled by the
L<Text-CSV_XS|http://search.cpan.org/dist/Text-CSV_XS/> library on CPAN.  Formats
frequently observed are B<tab-separated values>:

    path	nationality	gender	age	income	id_no

and B<pipe-separated values>:

    path|nationality|gender|age|income|id_no

The documentation for F<Text-CSV> comments that the CSV format could I<"...
perhaps better [be] called ASV (anything separated values)">, but we shall for
convenience use "CSV" herein regardless of the specific delimiter.

Since it is often the case that the characters used as column separators may
occur within the data recorded in the columns as well, it is customary to
quote either all columns:

    "path","nationality","gender","age","income","id_no"

... or, at the very least, all columns which can hold
data other than pure integers or floating-point numbers:

    "path","nationality","gender",age,income,id_no

=head3 Tree structure

To qualify as a taxonomy file, it is not sufficient for a file to be in CSV
format.  In each non-header record in that file, there must be one or more
columns which hold data capable of exactly specifying the record's position in
the taxonomy, I<i.e.,> the route from the root node to the node
being represented by that record.

The precise way in which certain columns are used to determine the path from
the root node to a given node is what differentiates various types of taxonomy
files from one another.  In Parse-Taxonomy we identify two different
flavors of taxonomy files and provide a class for the construction of each.

=head3 Taxonomy-by-materialized-path

A B<taxonomy-by-materialized-path> is one in which a single column -- which we will refer
to as the B<path column> -- serves as a B<materialized path>.  A materialized
path represents the route from the root to the given
record as a series of strings joined by separator characters.
Within that path column the value corresponding to the root node need
not be specified, I<i.e.,> may be represented by an empty string.

Let's rewrite Diagram 1 with values to make this clear.

B<Diagram 2:>

                               ""
                                |
                  ----------------------------------------------------
                  |                            |            |        |
                Alpha                        Beta         Gamma    Delta
                  |                            |            |
       -------------------------         ------------       |
       |                       |         |          |       |
    Epsilon                  Zeta       Eta       Theta   Iota
       |                       |                            |
       |                 ------------                       |
       |                 |          |                       |
     Kappa            Lambda        Mu                      Nu

Let us suppose that our taxonomy file held comma-separated, quoted records.
Let us further supposed that the column holding taxonomy paths was, not
surprisingly, called C<path> and that the separator within the C<path> column
was a pipe (C<|>) character.  Let us further suppose that for now we are not
concerned with the data in any columns other than C<path> so that, for purpose
of illustration, they will hold empty (albeit quoted) strings.

Then the taxonomy file describing the tree in Diagram 2 would look like this:

    "path","nationality","gender","age","income","id_no"
    "|Alpha","","","","",""
    "|Alpha|Epsilon","","","","",""
    "|Alpha|Epsilon|Kappa","","","","",""
    "|Alpha|Zeta","","","","",""
    "|Alpha|Zeta|Lambda","","","","",""
    "|Alpha|Zeta|Mu","","","","",""
    "|Beta","","","","",""
    "|Beta|Eta","","","","",""
    "|Beta|Theta","","","","",""
    "|Gamma","","","","",""
    "|Gamma|Iota","","","","",""
    "|Gamma|Iota|Nu","","","","",""
    "|Delta","","","","",""

Note that while in the C<|Gamma> branch we ultimately have only one leaf node,
C<|Gamma|Iota|Nu>, we require separate records in the taxonomy file for
C<|Gamma> and C<|Gamma|Iota>.  To put this another way, the existence of a
C<Gamma|Iota|Nu> leaf must not be assumed to "auto-vivify" C<|Gamma> and
C<|Gamma|Iota> nodes.  Each non-root node must be explicitly represented in
the taxonomy file for the file to be considered valid.

Note further that there is no restriction on the values of the B<components> of
the C<path> across records.  It only the B<full> path that must be unique.
Let us illustrate that by modifying the data in Diagram 2:

B<Diagram 3:>

                               ""
                                |
                  ----------------------------------------------------
                  |                            |            |        |
                Alpha                        Beta         Gamma    Delta
                  |                            |            |
       -------------------------         ------------       |
       |                       |         |          |       |
    Epsilon                  Zeta       Eta       Theta   Iota
       |                       |                            |
       |                 ------------                       |
       |                 |          |                       |
     Kappa            Lambda        Mu                    Delta

Here we have two leaf nodes each named C<Delta>.  However, we follow different
paths from the root node to get to each of them.  The taxonomy file
representing this tree would look like this:

    "path","nationality","gender","age","income","id_no"
    "|Alpha","","","","",""
    "|Alpha|Epsilon","","","","",""
    "|Alpha|Epsilon|Kappa","","","","",""
    "|Alpha|Zeta","","","","",""
    "|Alpha|Zeta|Lambda","","","","",""
    "|Alpha|Zeta|Mu","","","","",""
    "|Beta","","","","",""
    "|Beta|Eta","","","","",""
    "|Beta|Theta","","","","",""
    "|Gamma","","","","",""
    "|Gamma|Iota","","","","",""
    "|Gamma|Iota|Delta","","","","",""
    "|Delta","","","","",""

=head3 Taxonomy-by-adjacent-list

A B<taxonomy-by-adjacent-list> is one in which each record has a column with a
unique identifier (B<id>) and another column holding the unique identifier of
the record representing the next higher node in the hierarchy (B<parent_id>).
The record must also have a column which holds a datum that is unique among
all records having the same parent node.

Let's make this clearer by rewriting the taxonomy-by-materialized-path above
for Example 3 as a taxonomy-by-adjacent-list.

    "id","parent_id","name","nationality","gender","age","income","id_no"
    1,,"Alpha","","","","",""
    2,1,"Epsilon","","","","",""
    3,2,"Kappa","","","","",""
    4,1,"Zeta","","","","",""
    5,4,"Lambda","","","","",""
    6,4,"Mu","","","","",""
    7,,"Beta","","","","",""
    8,7,"Eta","","","","",""
    9,7,"Theta","","","","",""
    10,,"Gamma","","","","",""
    11,10,"Iota","","","","",""
    12,11,"Delta","","","","",""
    13,,"Delta","","","","",""

In the above taxonomy-by-adjacent-list, the records with C<id>s C<1>, C<7>, C<10>, and
C<13> are top-level nodes.   They have no parents, so the value of their
C<parent_id> column is null or, in Perl terms, an empty string.  The records
with C<id>s C<2> and C<4> are children of the record with C<id> of C<1>.  The
record with C<id 3> is, in turn, a child of the record with C<id 2>.

In the above taxonomy-by-adjacent-list, close inspection will show that no two records
with the same C<parent_id> share the same C<name>.  The property of
B<uniqueness of sibling names> means that we can construct a non-indexed
version of the path from the root to a given node by using the C<parent_id>
column in a given record to look up the C<name> of the record with the C<id>
value identical to the child's C<parent_id>.

    Via index: 3        2       1

    Via name:  Kappa    Epsilon Alpha

We go from C<id 3> to its C<parent_id>, <2>, then to C<2>'s C<parent_id>, <1>.
Putting names to this, we go from C<Kappa> to C<Epsilon> to C<Alpha>.

Now, reverse the order of those C<name>s, throw a pipe delimiter before each
of them and join them into a single string, and you get:

    |Alpha|Epsilon|Kappa

... which is the value of the C<path> column in the third record in the
taxonomy-by-materialized-path displayed previously.

With correct data, a given hierarchy of data can therefore be represented
either by a taxonomy-by-materialized-path or by a taxonomy-by-adjacent-list.
This permits us to describe these two taxonomies as B<equivalent> to each
other.

=head2 Taxonomy Validation

Each C<Parse::Taxonomy> subclass will have a constructor, C<new()>, whose
principal interface will take the name of a taxonomy file as an argument.  We
will call this interface the B<file> interface to the constructor.  The
purpose of the constructor will be to determine whether the taxonomy file
holds a valid taxonomy according to the description provided above.  The
arguments needed for such a constructor will be found in the documentation of
the subclass.

The constructor of a C<Parse::Taxonomy> subclass may, if desired, accept
a different set of arguments.  Suppose you have already read a CSV file and
parsed it into one array reference holding its header row -- a list of its
columns -- and a second array reference, this one being an array of arrays
where each element holds the data in one record in the CSV file.  You have the
same components needed to validate the taxonomy that you would get by
parsing the CSV file, so your subclass may implement a B<components> interface
as well as a file interface.

You should now proceed to read the documentation for
L<Parse::Taxonomy::MaterializedPath> and L<Parse::Taxonomy::AdjacentList>.

=cut

sub fields {
    my $self = shift;
    return $self->{fields};
}

sub data_records {
    my $self = shift;
    return $self->{data_records};
}

sub fields_and_data_records {
    my $self = shift;
    my @all_rows = $self->fields;
    for my $row (@{$self->data_records}) {
        push @all_rows, $row;
    }
    return \@all_rows;
}

sub get_field_position {
    my ($self, $f) = @_;
    my $fields = $self->fields;
    my $idx;
    for (my $i=0; $i<=$#{$fields}; $i++) {
        if ($fields->[$i] eq $f) {
            $idx = $i;
            last;
        }
    }
    if (defined($idx)) {
        return $idx;
    }
    else {
        croak "'$f' not a field in this taxonomy";
    }
}

1;

=head1 BUGS

There are no bug reports outstanding on Parse::Taxonomy as of the most recent
CPAN upload date of this distribution.

=head1 SUPPORT

Please report any bugs by mail to C<bug-Parse-Taxonomy@rt.cpan.org>
or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).  When sending correspondence, please
include 'Parse::Taxonomy' or 'Parse-Taxonomy' in your subject line.

Creation date:  May 24 2016.  Last modification date:  April 09 2016.

Development repository: L<https://github.com/jkeenan/parse-taxonomy>

=head1 REFERENCES

L<DBIx-Class-MaterializedPath|http://search.cpan.org/dist/DBIx-Class-MaterializedPath/>
by Arthur Axel "fREW" Schmidt

L<DBIx-Tree-MaterializedPath|http://search.cpan.org/dist/DBIx-Tree-MaterializedPath/>
by Larry Leszczynski

L<Trees in SQL: Nested Sets and Materialized Path|https://communities.bmc.com/docs/DOC-9902>
by Vadim Tropashko

L<DBIx-Tree|http://search.cpan.org/dist/DBIx-Tree/>, now maintained by Ron
Savage.

=head1 COPYRIGHT

Copyright (c) 2002-15 James E. Keenan.  United States.  All rights reserved.
This is free software and may be distributed under the same terms as Perl
itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE ''AS IS'' WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

# vim: formatoptions=crqot
