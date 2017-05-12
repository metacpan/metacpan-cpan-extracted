package Search::InvertedIndex::Simple;

# Name:
#	Search::InvertedIndex::Simple.
#
# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Reference:
#	Object Oriented Perl
#	Damian Conway
#	Manning
#	1-884777-79-1
#	P 114
#
# Note:
#	o Tab = 4 spaces || die.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html
#
# Licence:
#	Australian copyright (c) 1999-2002 Ron Savage.
#
#	All Programs of mine are 'OSI Certified Open Source Software';
#	you can redistribute them and/or modify them under the terms of
#	The Artistic License, a copy of which is available at:
#	http://www.opensource.org/licenses/index.html

use strict;
use warnings;
no warnings 'redefine';

require 5.005_62;

use Set::Array;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Search::InvertedIndex::Simple ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '1.04';

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(	# Alphabetical order.
		_dataset	=> [],
		_keyset		=> [],
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		sort keys %_attr_data;
	}

}	# End of Encapsulated class data.

# -----------------------------------------------

sub build_index
{
	my($self) = @_;

	my($i, $data, $key, $value, $offset, $prefix, %index);

	for $i (0 .. $#{$$self{'_dataset'} })
	{
		$data = $$self{'_dataset'}[$i];

		for $key (@{$$self{'_keyset'} })
		{
			$value			= $$data{$key};
			$index{$key}	= {} if (! $index{$key});

			for $offset (1 .. length $value)
			{
				$prefix					= substr($value, 0, $offset);
				$index{$key}{$prefix}	= [] if (! $index{$key}{$prefix});

				push @{$index{$key}{$prefix} }, $i;
			}
		}
	}

	for $key (keys %index)
	{
		for $prefix (keys %{$index{$key} })
		{
			$index{$key}{$prefix} = Set::Array -> new(@{$index{$key}{$prefix} });
		}
	}

	\%index;

}	# End of build_index.

# -----------------------------------------------

sub new
{
	my($caller, %arg)	= @_;
	my($caller_is_obj)	= ref($caller);
	my($class)			= $caller_is_obj || $caller;
	my($self)			= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		elsif ($caller_is_obj)
		{
			$$self{$attr_name} = $$caller{$attr_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	$self;

}	# End of new.

# -----------------------------------------------

1;

__END__

=head1 NAME

Search::InvertedIndex::Simple - Build indexes for a set of search keys

=head1 Synopsis

See below for a warning about Set::Array V 0.11.

	my($dataset) = [
	               { # Index: 0.
	               	 address => 'Here',
	               	 event   => 'Start',
	               	 time    => 'Now',
	               },
	               { # Index: 1.
	               	 address => 'Heaven',
	               	 event   => 'Exit',
	               	 time    => 'Then',
	               },
	               { # Index: 2.
	               	 address => 'There',
	               	 event   => 'Finish',
	               	 time    => 'Thus',
	               }
	               ];
	my($keyset)  = [qw/address time/];
	my($index)   = Search::InvertedIndex::Simple -> new
	               (
	                   dataset => $dataset,
	                   keyset  => $keyset,
	               ) -> build_index();
	my(@index)   = $$index{'address'}{'He'} -> intersection($$index{'time'}{'T'}) );

This code is discussed in the next section.

See t/test.t for a complete program.

=head1 Description

C<Search::InvertedIndex::Simple> is a pure Perl module.

You might like to run the example program before reading this explanation.

The input to new(dataset => $a, keyset => $k) is an arrayref of data (each element of which is a hashref),
and an arrayref of keys.

The arrayref of data is in the format returned by many DBI methods,
eg DBI's C<fetchall_arrayref({})> and DBIx::SQLEngine's C<fetch_select()>.

The arrayref of keys is used to select a subset of the keys within each hashref.

These selected keys become the primary keys in the hashref returned by the method C<build_index()>.

In the example in the synopsis, C<build_index()> will return a hashref with the primary keys 'address' and 'time'.

The values (assumed to be strings) from the arrayref of data corresponding to those keys are used to create
a set of secondary keys under each of these primary keys.

The secondary keys are created by taking these values, growing them one character at a time, and using these
generated strings as the secondary keys in the hashref returned by the method C<build_index()>.

In the example in the synopsis, C<build_index()> will return a hashref where the primary key 'address'
will have these secondary keys: H, He, Hea, Heav, Heave, Heaven, Her, Here, T, Th, The, Ther, There.

This means that all data values for the key 'address', and all prefixes of those values, are used to
create entries in the returned hashref.

Similary, the primary key 'time' will have a set of secondary keys.

It should be clear by now that these sets of secondary keys can be used for searching for the existence of values,
eg by using as input user-supplied data of any length. At the same time, any number of keys can be searched for
simultaneously.

Hence we have (using the example data above):

	my($indexer) = Search::InvertedIndex::Simple -> new(...);
	my($index)   = $indexer -> build_index();

where

	$$index{'address'} is a hashref, and
	$$index{'address'}{'H'} is X, and
	$$index{'address'}{'He'} is Y.

But what are X and Y? They are objects of type Set::Array, and they contain lists of array indexes.

The values of these indexes are the indexes from the original dataset which contributed to the construction
of the hashref of secondary keys under each primary key.

That is:

	$$index{'address'}{'H'} is an object of type Set::Array -> new(0, 1)

because indexes 0 and 1 in the dataset contain an address starting with 'H'.

And:

	$$index{'address'}{'He'} is an object of Set::Array -> new(0, 1)

for the same reason.

But:

	$$index{'address'}{'Hea'} is an object of Set::Array -> new(1)
	$$index{'address'}{'Her'} is an object of Set::Array -> new(0)

because address 'Hea' comes from index 1 in the dataset, and address 'Her' comes from index 0.

Similarly:

	$$index{'time'}{'T'} is an object of Set::Array -> new(1, 2)

because time 'T' comes from dataset indexes 1 (time => Then) and 2 (time => Thus).

Now we can tell instantaneously which elements of the dataset contain the results of a multi-key search:

	@index = $$index{'address'}{'He'} -> intersection($$index{'time'}{'T'}) );

That is, @index = (1). In other words, $$dataset[1] contains the only hashref where we have an address
value starting with 'He' and a time value starting with 'T'.

Here, C<intersection()> is a method available to objects of type Set::Array, and it returns a list.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<Search::InvertedIndex::Simple> object.

This is the class's contructor.

Parameters to C<new()>:

=over 4

=item dataset

This is an arrayref of hashrefs containing the data to be processed.

This parameter is mandatory.

=item keyset

This is an arrayref of keys used to extract values from the hashrefs in the dataset.

This parameter is mandatory.

=back

=head1 Method: C<build_index()>

This method creates a hashref using as primary keys the values from the arrayref keyset passed into C<new()>,
and as secondary keys values generated (as explained above) from each hashref in the dataset passed into C<new()>.

It returns the hashref so created.

=head1 Example code

See t/test.t for a complete program.

=head1 Author

C<Search::InvertedIndex::Simple> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2005.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2005, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
