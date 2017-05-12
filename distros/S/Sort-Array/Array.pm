# Sort::Array.pm
#
# Copyright (c) 2001 Michael Diekmann <michael.diekmann@undef.de>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# Documentation could be found at the bottom or use (after install):
# > perldoc Sort::Array

package Sort::Array;

require 5.003_03;
require Exporter;

use strict;
use vars qw(@EXPORT_OK @ISA $VERSION $error);
@ISA = qw(Exporter);

# we export nothing by default :)
@EXPORT_OK = qw(
	Sort_Table
	Discard_Duplicates
);

$VERSION = '0.26';

#///////////////////////////////////////////////////////////////////////#
#									#
#///////////////////////////////////////////////////////////////////////#

sub Discard_Duplicates {
	# Get the args and put them into a Hash.
    	my (%arg) = @_;
	$error = 0;

	# Check for content that should be sorted,
	# else return error-code.
	if (scalar(@{$arg{data}}) == 0) {
		$error = 104;
		return undef;
	}

	my $use_warn = 0;
	# Turn warnings off, because we do first a '<=>' and if that
	# fails, we do a 'cmp'. And then a warning comes up.
	# After working, we turn $^W to the same as before.
	if ($^W) {
		$use_warn = $^W;
		$^W = 0;
	}

	# Find duplicates and sort them out.
	my %seen = ();
	my @unique = grep { ! $seen{$_}++ } @{$arg{data}};
	%seen = ();

	# Check if <sorting> is set, if empty do not sort them.
	if ($arg{sorting} eq 'ascending') {
		# Sorting content ascending order.
		@unique = sort { $a <=> $b || $a cmp $b } @unique;
	}
	elsif ($arg{sorting} eq 'descending') {
		# Sorting content descending order.
		@unique = sort { $b <=> $a || $b cmp $a } @unique;
	}

	# Turn warnings to the same as before.
	if ($use_warn) {
		$^W = $use_warn;
	}

	# Remove all empty fields, if wished.
	if ($arg{empty_fields} eq 'delete') {
		@_ = ();
		foreach (@unique) {
			push(@_, $_) if $_;
		}
		@unique = @_;
	}
#	return @unique;
	@{$arg{data}} = @unique;
}

#///////////////////////////////////////////////////////////////////////#
#									#
#///////////////////////////////////////////////////////////////////////#

sub Sort_Table {
	# Get the args and put them into a Hash.
    	my (%arg) = @_;
	$error = 0;

	# Check if <cols> is set,
	# else return error-code.
	if ((! $arg{cols}) && ($arg{cols} !~ /0-9/)) {
		$error = 100;
		return undef;
	}

	# Check if <field> is set,
	# else return error-code.
	if ((! $arg{field}) && ($arg{field} !~ /0-9/)) {
		$error = 101;
		return undef;
	}

	# Check if <sorting> is set,
	# else return error-code.
	if ((! $arg{sorting}) && (($arg{sorting} ne 'ascending') || ($arg{sorting} ne 'descending'))) {
		$error = 102;
		return undef;
	}

	# Check if <structure> set,
	# else return error-code.
	if (! $arg{structure}) {
		$error = 103;
		return undef;
	}

	# Check for content that should be sorted,
	# else return error-code.
	if (scalar(@{$arg{data}}) == 0) {
		$error = 104;
		return undef;
	}

	# Check is <separator> set,
	# else set the standard > ";"
	if (! $arg{separator}) {
		$arg{separator} = ';';
	}

	# Subtract 1 for better readable Arrayfields ->
	# beginning count at 1 (not 0). ;)
	$arg{cols}--;
	$arg{field}--;

	if ($arg{structure} eq 'single') {
		# Array is not semicolon-separated and we must
		# convert it to semicolon-separated.
		@_ = ();
		my $i=0;
		while (defined ${$arg{data}}[$i] ne '') {
			my $tmp='';
			for (0..$arg{cols}) {
				$tmp .= "${$arg{data}}[$i+$_]";
				if ($_ != $arg{cols}) {
					$tmp .= "$arg{separator}";
				}
			}
			push(@_, $tmp);
			$i += $arg{cols} + 1;
		}
		@{$arg{data}} = @_;
	}

	my $use_warn = 0;
	# Turn warnings off, because we do first a '<=>' and if that
	# fails, we do a 'cmp' and then a warning comes up.
	# After sorting, we turn $^W to the same as before.
	if ($^W) {
		$use_warn = $^W;
		$^W = 0;
	}
	if ($arg{sorting} eq 'ascending') {
		# Sorting content ascending order.
		@{$arg{data}} =
			map { $_->[0] }
			sort {
				$a->[1] <=> $b->[1]
					||
				$a->[1] cmp $b->[1]
			}
			map { [ $_, (split(/$arg{separator}/))[$arg{field}] ] }
		@{$arg{data}};
	}
	elsif ($arg{sorting} eq 'descending') {
		# Sorting content descending order.
		@{$arg{data}} =
			map { $_->[0] }
			sort {
				$b->[1] <=> $a->[1]
					||
				$b->[1] cmp $a->[1]
			}
			map { [ $_, (split(/$arg{separator}/))[$arg{field}] ] }
		@{$arg{data}};
	}

	# Turn warnings to the same as before.
	if ($use_warn) {
		$^W = $use_warn;
	}

	# Return the sorted Array in the
	# same format as input.
	if ($arg{structure} eq 'csv') {
		return @{$arg{data}};
	}
	elsif ($arg{structure} eq 'single') {
		@_ = ();
		foreach (@{$arg{data}}) {
			push(@_, split(/$arg{separator}/));
		}
		return @_;
	}
}

1;

__END__

#///////////////////////////////////////////////////////////////////////#
#									#
#///////////////////////////////////////////////////////////////////////#

=head1 NAME

Sort::Array - This extended sorting algorithm allows you to

a) sort an array by ANY field number, not only the first.
b) find duplicates in your data-set and sort them out.

The function is case-sensitive. Future versions might come without
this limitation.



=head1 SYNOPSIS

  use Sort::Array qw(
      Sort_Table
      Discard_Duplicates
  );
  @data = Sort_Table(
      cols      => '4',
      field     => '4',
      sorting   => 'descending',
      structure => 'csv',
      separator => '\*',
      data      => \@data,
  );
  @languages = Discard_Duplicates(
      sorting      => 'ascending',
      empty_fields => 'delete',
      data         => \@languages,
  );



=head1 DESCRIPTION

Sort_Table() is capable of sorting table-form arrays by a particular value.

Discard_Duplicates() discards doubles from an array and returns
the sorted array.


=head2 Usage

  @data = Sort_Table(
      cols      => '4',
      field     => '4',
      sorting   => 'descending',
      structure => 'csv',
      separator => '\*',
      data      => \@data,
  );

  @languages = Discard_Duplicates(
      sorting      => 'ascending',
      empty_fields => 'delete',
      data         => \@languages,
  );

=over 1

=item cols

 How many columns in a line. Integer beginning at
 1 (not 0) (for better readability).
 e.g.: '4' = Four fields at one line. ($array[0..3])
 - Utilizable only in Sort_Table()
 - Must be declared

=item field

 Which column should be used for sorting. Integer
 beginning at 1 (not 0).
 e.g.: '4' = Sorting the fourth field. ($array[3])
 - Utilizable only in Sort_Table()
 - Must be declared

=item sorting

 In which order should be sorted.
 e.g.: 'ascending' or 'descending'
 - Utilizable in Sort_Table()
 - Must be declared

 - Utilizable in Discard_Duplicates()
 - Can be declared (if empty, it does not sort the array)

=item empty_fields

 Should empty fields removed
 e.g.: 'delete' or not specified
 - Utilizable only in Discard_Duplicates()
 - Can be declared

=item structure

 Structure of that Array.
 e.g.: 'csv' or 'single'
 - Utilizable only in Sort_Table()
 - Must be declared

=item separator

 Which separator should be used? Only needed when
 structure => 'csv' is set. If left empty default
 is ";".
 For ?+*{} as a separator you must mask it since
 it is a RegEx.
 e.g.: \? or \* ...
 - Utilizable only in Sort_Table()
 - Must be declared when using 'csv' or ';'
     will be used.

=item data

 Reference to the array that should be sorted.
 - Utilizable in Sort_Table() and Discard_Duplicates()
 - Must be declared

=back

If everything went right, Sort_Table() returns an array containing
your sorted Array. The structure from the imput-array is kept although
it's sorted. ;)



=head2 Returncodes

If an error occurs, than will be returned an undefinied array and set
$Sort::Array::error with one of the following code. Normally $Sort::Array::error
is 0.

The following codes are returned, if an error occurs:

=over 2

=item '100'

<cols> is empty or not set or contains wrong content.

=item '101'

<field> is emtpy or not set or contains wrong content.

=item '102'

<sorting> is empty or contains not 'ascending' or 'descending'.

=item '103'

<structure> is empty or contains not 'csv' or 'single'.

=item '104'

<data> is empty (your reference array).

=back



=head1 EXAMPLES

Here are some short samples. These should help you getting
used to Sort::Array



=head2 Sorting CSV-Lines in an array

  my @data = (
     '00003*layout-3*19990803*0.30',
     '00002*layout-2*19990802*0.20',
     '00004*layout-4*19990804*0.40',
     '00001*layout-1*19990801*0.10',
     '00005*layout-5*19990805*0.50',
     '00007*layout-7*19990807*0.70',
     '00006*layout-6*19990806*0.60',
  );

  @data = Sort_Table(
      cols      => '4',
      field     => '4',
      sorting   => 'descending',
      structure => 'csv',
      separator => '\*',
      data      => \@data,
  );

  Returns an array (with CSV-Lines):

  00007*layout-7*19990807*0.70
  00006*layout-6*19990806*0.60
  00005*layout-5*19990805*0.50
  00004*layout-4*19990804*0.40
  00003*layout-3*19990803*0.30
  00002*layout-2*19990802*0.20
  00001*layout-1*19990801*0.10



=head2 Sorting single-fields in an array

  my @data = (
     '00003', 'layout-3', '19990803', '0.30',
     '00002', 'layout-2', '19990802', '0.20',
     '00004', 'layout-4', '19990804', '0.40',
     '00001', 'layout-1', '19990801', '0.10',
     '00005', 'layout-5', '19990805', '0.50',
     '00007', 'layout-7', '19990807', '0.70',
     '00006', 'layout-6', '19990806', '0.60',
  );

  @data = Sort_Table(
      cols      => '4',
      field     => '4',
      sorting   => 'descending',
      structure => 'single',
      data      => \@data,
  );

  Returns an array (with single fields)

  00007 layout-7 19990807 0.70
  00006 layout-6 19990806 0.60
  00005 layout-5 19990805 0.50
  00004 layout-4 19990804 0.40
  00003 layout-3 19990803 0.30
  00002 layout-2 19990802 0.20
  00001 layout-1 19990801 0.10



=head2 Discard duplicates in an array:

  my @languages = (
      '',
      'German',
      'Dutch',
      'English',
      'Spanish',
      '',
      'German',
      'Spanish',
      'English',
      'Dutch',
  );

  @languages = Discard_Duplicates(
      sorting      => 'ascending',
      empty_fields => 'delete',
      data         => \@languages,
  );

  Returns an array (with single fields):

  Dutch
  English
  German
  Spanish



=head1 BUGS

No Bugs known for now. ;)



=head1 HISTORY

=item - 2001-08-25 / 0.26

File permission fixed, now anybody can extract the archive, not
only the user 'root'.

=item - 2001-08-23 / 0.25

Changed the Discard_Duplicates() function to discard duplicates
and only sort the array if wished. You can set <sorting> to
'asending', 'desending' or let them empty to disable sorting.

Some misspelling corrected.

=item - 2001-08-17 / 0.24

Error codes are no longer returned in an array (that array that
contains the sorted Data). $Sort::Array::error is used with the
code instead.

=item - 2001-07-28 / 0.23

First beta-release, non-public



=head1 AUTHOR

Michael Diekmann, <michael.diekmann@undef.de>



=head1 THANKS

Rainer Luedtke, <sirbedivere@freshfish.de>



=head1 COPYRIGHT

Copyright (c) 2001 Michael Diekmann <michael.diekmann@undef.de>. All rights
reserved. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.



=head1 SEE ALSO

perl(1).

=cut
