package Pivot::ArrayOfHashes 1.0000;

# ABSTRACT: Pivot arrays of hashes, such as those returned by DBI

use strict;
use warnings;

use 5.006;
use v5.12.0;    # Before 5.006, v5.10.0 would not be understood.

use UUID       qw{uuid};
use List::Util qw{uniq};
use parent 'Exporter';
our @EXPORT_OK = qw{pivot};

sub pivot {
    my ( $rows, %opts ) = @_;

    # Extract the pivoted cols.
    my @data = uniq map { $_->{ $opts{pivot_into} } } @$rows;

    # Vital for grouping the data.
    my $data_splitter = uuid();
    my $row_splitter  = uuid();

    # First, we group by the nonspecified cols.
    # We do this by creating string aggregations of the relevant data.
    my @set;
    foreach my $row (@$rows) {
        my @s;
        foreach my $key ( sort keys(%$row) ) {
            next if $key eq $opts{pivot_on} || $key eq $opts{pivot_into};
            push( @s, "$key$data_splitter$row->{$key}" );
        }
        push( @set, join( $row_splitter, @s ) );
    }

    # Next, we reverse the process into a hash after a uniq() filter.
    # Whether this is done with hash keys or uniq() is of little consequence, we would have to reexpand them.
    my @grouped = map {
        my $subj = $_;
        my %h    = map { split( /\Q$data_splitter\E/, $_ ) }
          ( split( /\Q$row_splitter\E/, $subj ) );
        \%h
    } uniq(@set);

    # Next, we have to pivot.
    @grouped = map {
        my $subj      = $_;
        my @orig_keys = keys(%$subj);

        # Make sure to null-fill all the relevant pivoted data points.
        foreach my $param (@data) {
            $subj->{$param} = undef;
        }

        foreach my $row (@$rows) {

            # Append this row's info iff we are in the group.
            next
              unless scalar( grep { $subj->{$_} eq $row->{$_} } @orig_keys ) ==
              scalar(@orig_keys);

            my $field = $row->{ $opts{pivot_into} };
            $subj->{$field} = $row->{ $opts{pivot_on} };
        }
        $subj
    } @grouped;

    return @grouped;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pivot::ArrayOfHashes - Pivot arrays of hashes, such as those returned by DBI

=head1 VERSION

version 1.0000

=head1 SYNOPSIS

	# Suppose you have some result from DBI::selectall_arrayref(..., { Slice => {} });
	my @rows = (
		{ name => 'fred',  'lname' => 'flintstone', 'events' => 'Chase, Hugs',         date => '2025-01-01' },
		{ name => 'fred',  'lname' => 'flintstone', 'events' => 'Chase, Tickle, Hugs', date => '2025-01-02' },
		{ name => 'fred',  'lname' => 'flintstone', 'events' => 'Tickle',              date => '2025-01-03' },
		{ name => 'wilma', 'lname' => 'flintstone', 'events' => 'Chase, Tickle, Hugs', date => '2025-01-01' },
		{ name => 'wilma', 'lname' => 'flintstone', 'events' => 'Tickle',              date => '2025-01-02' },
		{ name => 'fred',  'lname' => 'rubble',     'events' => 'Chase, Hugs',         date => '2025-01-01' },
	);

	# I want events by date, and to group by each of the other cols.
	# In short, "what is everyone on what date".
	my %options = (
		pivot_on   => 'events',
		pivot_into => 'date',
	);

	# Using our function!
	my @pivoted = pivot(\@rows, %options);

	# Returns an array like so:
	my $r = [
		{
			'name'                   => 'fred',
			'lname'                  => 'flintstone',
			'2025-01-01 00:00:00+00' => 'Chase, Hugs',
			'2025-01-02 00:00:00+00' => 'Chase, Tickle, Hugs',
			'2025-01-03 00:00:00+00' => 'Tickle',
			},
			{
			'name'                   => 'wilma',
			'lname'                  => 'flintstone',
			'2025-01-01 00:00:00+00' => 'Chase, Tickle, Hugs',
			'2025-01-02 00:00:00+00' => 'Tickle',
			'2025-01-03 00:00:00+00' => undef,
			},
			{
			'name'                   => 'fred',
			'lname'                  => 'rubble',
			'2025-01-01 00:00:00+00' => 'Chase, Hugs',
			'2025-01-02 00:00:00+00' => undef,
			'2025-01-03 00:00:00+00' => undef,
		},
	];

=head1 DESCRIPTION

Pivot a very specific type of resultset, namely an array of hashes closely resembling database rows such as those returned by DBI in hash select mode.

This simplifies any interface having to pivot data outside of the DB, allowing it to be a more generic solution using less code.

Groups by the columns not pivoted on/into.  This may get out of hand if you have many irrelevant columns returned.

See SYNOPSIS below for a detailed example.

=head1 RATIONALE

Nowadays you would be recommended to do this in-db like most things,
however in most cases a generic solution to pivoting requires extensions which may or not be available in your environment.

No module on CPAN as of writing, despite many venerable pivoters existing, have such a simple interface.
The only one I am aware of operating on similar data accomplishes the same with 4x more code.
Hopefully this means that if you have an issue with it the problems are easier to reason about.

=head1 BATCHING

A core challenge when pivoting tables is memory usage.
One cannot be absolutely sure you have fully built a pivoted row until all results for a given group have been processed, which may be components of any input row.
In short you will want to use 'keyset' pagination via constraints rather than offset pagination.

=head1 FUNCTIONS

=head2 pivot(ARRAYREF $rows, HASH %opts)

Pivot the provided $rows according to the provided %opts:

    pivot_into: what column's data in the $rows shall constitute the new columns.
    pivot_on:   what column's data in the $rows shall constitute the row data for the new columns.

A key implementation detail to be aware of here is that the grouping of the extraneous data relies on a double string aggregation.
We split the data with UUIDs from the eponymous module, so this ought not to cause you any data misclassifications.
However, if the data in such a column returned is not losslessly interpolable into a string this will cause issues.

You should expect as many rows to be output as there are unique concatenations of nonpivoted data.
You should never get more rows than you input, and will likely get substantially less in most real-world use cases.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Pivot-ArrayOfHashes/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
