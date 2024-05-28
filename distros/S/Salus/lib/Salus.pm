package Salus;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.08';

use Salus::Header;
use Salus::Table;

my (%PRO, %META);
BEGIN {
	%PRO = (
		keyword => sub {
			no strict 'refs';
			my ($caller, $keyword, $cb) = @_;
			*{"${caller}::${keyword}"} = $cb;
		},
		clone => sub {
                        my $obj = shift;
                        my $ref = ref $obj;
                        return $obj if !$ref;
                        return [ map { $PRO{clone}->($_) } @{$obj} ] if $ref eq 'ARRAY';
                        return { map { $_ => $PRO{clone}->($obj->{$_}) } keys %{$obj} } if $ref eq 'HASH';
                        return $obj;
                }
	);
}

sub import {
	my ($pkg, %import) = @_;

	my $caller = caller();

	if (exists $import{header} ? $import{header} : $import{all}) {
		my ($index, %indexes) = (0, ());
		$PRO{keyword}($caller, 'header', sub {
			my ($name, %options) = @_;
			$options{name} = $name;
			push @{$META{$caller}{headers}}, \%options;
		});
	}

	if (exists $import{new} ? $import{new} : $import{all}) {
		$PRO{keyword}($caller, 'new', sub {
			my ($pkg, %options) = @_;
			__PACKAGE__->new($META{$caller}, \%options, $pkg);
		});
	}
}

sub new {
	my ($self, $meta, $options, $caller) = @_;
	
	$meta = $PRO{clone}($meta);

	my ($i, @headers, %properties) = (0, (), ());

	my %indexes = map {
		$_->{index} ? ($_->{index} => 1) : ()
	} @{ $meta->{headers} };

	for my $header (@{$meta->{headers}}) {
		while (1) {
			unless ($indexes{$i}) {
				$indexes{$i}++;
				$header->{index} = $i;		
				last;
			}
			++$i;
		}
		push @headers, Salus::Header->new(%{$header});
	}

	return Salus::Table->new(
		%{$options},
		headers => \@headers,
		rows => $meta->{rows} || []
	);
}

1;

__END__;

=head1 NAME

Salus - checksummed csvs

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

	package Corruption;

	use Salus all => 1;

	header id => (
		label => 'ID',
	);

	header firstName => (
		label => 'First Name',
	);

	header lastName => (
		label => 'Last Name',
	);

	header header => (
		label => 'Age',
	);

	1;

...

	my $unethical = Corruption->new(
		file => 't/test.csv',
		unprotected_read => 1
	);

	$unethical->read();

	$unethical->write('t/test2.csv');

=head1 ATTRIBUTES

=cut

=head2 file

The file to be read

=head2 secret

The secret used for the hmac

=head2 unprotected_read

Set if you would like to read an unprotected csv

=head2 headers

The headers used for parsing and writing the csv

=head2 rows

The data stored in the Salus object

=head1 METHODS

=cut

=head2 new

	my $salus = Salus->new({
		secret => 'xyz',
		headers => [
			{
				name => 'id',
				label => 'ID'
			},
			...
		]
	});

	$salus->add_rows([
		[1, 'Robert', 'Acock', 32],
		[2, 'Jack', 'Joy', 33],
		[3, 'Pluto', 'Hades', 34]
	]);

	$salus->combine('t/test.csv', 'id');

	$salus->get_row(2)->as_array;

=cut

=head2 read

Read a Salus csv file into memory, the function accepts two params the first is a filename, the second is optional and if a true value is passed the rows will be returned without them being cached inside of Salus itself.

	$salus->read('test.csv');

Note: if your csv was not generated using salus then you will want to enable "unprotected_read" first.

=cut

=head2 combine

Combine another csv with the existing data stored in the Salus object, the function expects two params the first is a filename, the second is the column on which to overwrite the rows value if there is a match.

	$salus->combine('testing.csv', 'id');

=cut

=head2 write

Write the Salus data to a csv file.

	$salus->write("new.csv");

=cut

=head2 count

Returns the total number of rows stored in the Salus object.

	$salus->count;

=cut

=head2 add_row

Add a single row to the Salus object.

	$salus->add_row([
		1, 'Robert', 'Acock', 32
	]);

=cut

=head2 add_rows

Add multiple rows to the Salus object.

	$salus->add_rows([
		[2, 'Jack', 'Joy', 33],
		[3, 'Pluto', 'Hades', 34]
	]);

=cut

=head2 add_row_hash

Add a single row to the Salus object passing the data as a hash

	$salus->add_row_hash({
		id => 1, 
		...
	});

=cut

=head2 get_row

Get a single row. This function expects a single param that represents the row index you would like to get.
	
	$salus->get_row(0);

=cut

=head2 get_row_col

Get a single row column. This function expects two params that represent the row index and the column index or name you would like to get.

	$salus->get_row_col(0, 1);

=cut

=head2 set_row 

Set a single row. This function expects two params the first that represents the row index to update and the second that is an arrayref representing column values to update.

	$salus->set_row(0, [1, 'Robert', 'Acock', 32]);

=cut

=head2 set_row_col

Set a single rows column value. This function expects three params the first that represents the row index, the second a column index or name and finally the third which should contain the value that will be used to update the rows column.

	$salus->set_row_col(0, 3, 33);

=cut

=head2 delete_row

Delete a single row. This function expects a single param that represents the row index you would like to delete.

	$salus->delete_row(0);

=cut

=head2 delete_row_col

Delete a single row column. This function expects two params that represent the row index and the column index or name you would like to clear.

	$salus->delete_row_col(0, 1);

=cut

=head2 sort

Sort the Salus object rows. This function expects three params, the column index or name, the order to sort and a boolean value to toggle whether or not to store the results in the sorted order.

	$salus->sort(1, 'asc'); # will store the sorted rows
	$salus->sort(1, 'desc', 1); # will only return the sorted rows

=cut

=head2 search

Search the Salus object rows. This function expects two params, the column index or name to search and the string to search for. It will return all matches within the stored rows.

	$salus->search('firstName', 'Robert'); 

=cut

=head2 find

Search the Salus object row index. This function expects two params, the column index or name to search and the string to search for. It will return the first matches row index.

	$salus->find('firstName', 'Robert');

=cut

=head2 find_column_index

Find the column index by column header name.

	$salus->find_column_index('firstName');

=cut

=head2 sum

Perform a sum aggregation on a column.

	$salus->sum('age');

=cut

=head2 mean

Perform a mean aggregation on a column.

	$salus->mean('age');

=cut

=head2 median

Perform a median aggregation on a column.

	$salus->median('age'); # returns the value
	$salus->median('age', 1); # returns the row

=cut

=head2 mode

Perform a mode aggregation on a column.

	$salus->mode('age');

=cut

=head2 min

Find the minimum value for a column

	$salus->min('age'); # returns the value
	$salus->min('age', 1); # returns the row

=cut

=head2 max

Find the miximum value for a column

	$salus->max('age'); # returns the value
	$salus->max('age', 1); # returns the row

=cut

=head2 headers_as_array

Returns all headers stringified as label || name as an arrayref.

	$salus->headers_as_array;

=head2 headers_stringify

Returns all headers stringified including label, name and index as an arrayref.

	$salus->headers_stringify;

=head2 diff_files

Diff two files using Text::Diff.

	$salus->diff_files($file1, $file2);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-salus at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Salus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Salus

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Salus>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Salus>

=item * Search CPAN

L<https://metacpan.org/release/Salus>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Salus
