# $Id: MultipleFields.pm,v 1.11 2008/07/28 21:53:23 drhyde Exp $

package Sort::MultipleFields;

use strict;
use warnings;

use vars qw($VERSION @EXPORT_OK @ISA);

use Scalar::Util qw(reftype);

use Exporter; # 5.6's Exporter doesn't export its import function, so
              # need to do the inheritance dance.  Joy.
@ISA = qw(Exporter);
@EXPORT_OK = qw(mfsort mfsortmaker);

$VERSION = '1.01';

=head1 NAME

Sort::MultipleFields - Conveniently sort on multiple fields

=head1 SYNOPSIS

    use Sort::MultipleFields qw(mfsort);

    my $library = mfsort {
        author => 'ascending',
        title  => 'ascending'
    } (
        {
            author => 'Hoyle, Fred',
            title  => 'Black Cloud, The'
        },
        {
            author => 'Clarke, Arthur C',
            title  => 'Rendezvous with Rama'
        },
        {
            author => 'Clarke, Arthur C',
            title  => 'Islands In The Sky'
        }
    );

after which C<$library> would be a reference to a list of three hashrefs,
which would be (in order) the data for "Islands In The Sky", "Rendezvous
with Rama", and "The Black Cloud".

=head1 DESCRIPTION

This provides a simple way of sorting structured data with multiple fields.
For instance, you might want to sort a list of books first by author and
within each author sort by title.

=head1 EXPORTS

The subroutines may be exported if you wish, but are not exported by
default.

Default-export is bad and wrong and people who do it should be spanked.

=head1 SUBROUTINES

=head2 mfsort

    @sorted = mfsort { SORT SPEC } @unsorted;

Takes a sort specification and a list (or list-ref) of references to hashes.
It returns either a list or a list-ref, depending on context.

The sort specification is a block structured thus:

    {
        field1 => 'ascending',
        field2 => 'descending',
        field3 => sub {
            lc($_[0]) cmp lc($_[1]) # case-insensitive ascending
        },
        ...
    }

Yes, it looks like a hash.  But it's not, it's a block that returns a
list, and order matters.

The spec is a list of pairs, each consisting of a field to sort on, and
how to sort it.  How to sort is simply a function that, when given a
pair of pieces of data, will return -1, 0 or 1 depending on whether the first
argument is "less than", equal to, or "greater than" the second argument.
Sounds familiar, doesn't it.  As short-cuts for the most common sorts,
the following case-insensitive strings will work:

=over

=item ascending, or asc

Sort ASCIIbetically, ascending (ie C<$a cmp $b>)

=item descending, or desc

Sort ASCIIbetically, descending (ie C<$b cmp $a>)

=item numascending, or numasc

Sort numerically, ascending (ie C<< $a <=> $b >>)

=item numdescending, or numdesc

Sort numerically, descending (ie C<< $b <=> $a >>)

=back

Really old versions
of perl might require that you instead pass the sort spec as an
anonymous subroutine.

    mfsort sub { ... }, @list

=cut

sub mfsort(&@) {
    my $spec = shift;
    my @records = @_;
    @records = @{$records[0]} if(reftype($records[0]) eq 'ARRAY');
    (grep { reftype($_) ne 'HASH' } @records) &&
        die(__PACKAGE__."::mfsort: Can only sort hash-refs\n");

    my $sortsub = mfsortmaker($spec);
    @records = sort { $sortsub->($a, $b) } @records;
    return wantarray() ? @records : \@records;
}

=head2 mfsortmaker

This takes a sort spec subroutine reference like C<mfsort> but returns
a reference to a subroutine that you can use with the built-in C<sort>
function.

    my $sorter = mfsortmaker(sub {
        author => 'asc',
        title  => 'asc'
    });
    @sorted = sort $sorter @unsorted;

Note that you need to store the generated subroutine in a variable before
using it, otherwise the parser gets confused.

Using this function to generate functions for C<sort> to use should be
considered to be experimental, as it can make some versions of perl
segfault.  It appears to be reliable if you do this:

    my $sorter = mfsortmaker(...);
    @sorted = sort { $sorter->($a, $b) } @unsorted;

and that's what the C<mfsort> function does internally.

=cut

sub mfsortmaker {
    my $spec = shift;
    my @spec = $spec->();

    my $sortsub = sub($$) { 0 }; # default is to not sort at all
    while(@spec) { # eat this from the end towards the beginning
        my($spec, $field) = (pop(@spec), pop(@spec));
        die(__PACKAGE__."::mfsortmaker: malformed spec after $field\n")
            unless(defined($spec));
        if(!ref($spec)) { # got a string
            $spec = ($spec =~ /^asc(ending)?$/i)     ? sub { $_[0] cmp $_[1] } :
                    ($spec =~ /^desc(ending)?$/i)    ? sub { $_[1] cmp $_[0] } :
                    ($spec =~ /^numasc(ending)?$/i)  ? sub { $_[0] <=> $_[1] } :
                    ($spec =~ /^numdesc(ending)?$/i) ? sub { $_[1] <=> $_[0] } :
                    die(__PACKAGE__."::mfsortmaker: Unknown shortcut '$spec'\n");
        }
        my $oldsortsub = $sortsub;
        $sortsub = sub($$) {
            $spec->($_[0]->{$field}, $_[1]->{$field}) ||
            $oldsortsub->($_[0], $_[1])
        }
    }
    # extra layer of wrapping seems to prevent segfaults in 5.8.8. WTF?
    # return $sortsub
    return sub($$) {
        # use Data::Dumper;print(map { Dumper($_) } @_);print "\n\n";
        $sortsub->(@_)
    };
}

=head1 BUGS, LIMITATIONS and FEEDBACK

If you find undocumented bugs please report them either using
L<http://rt.cpan.org/> or by email.  Ideally, I would like to receive
sample data and a test file, which fails with the latest version of
the module but will pass when I fix the bug.

For some unknown reason, passing C<sort> a particularly complex subroutine
generated using mfsortmaker can sometimes make perl 5.8.8 (and possibly
earlier versions) segfault.  I *think* I've worked around it, and at least
it doesn't happen for me any more, but YMMV.  It was something of a
Heisenbug so the current fix doesn't fill me with confidence.

=cut

=head1 SEE ALSO

L<Sort::Fields> for sorting data consisting of strings with fixed-length
fields in them.

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2008 David Cantrell E<lt>david@cantrell.org.ukE<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
