package Search::InvertedIndex::Simple::BerkeleyDB;

# Name:
#	Search::InvertedIndex::Simple::BerkeleyDB.
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

use BerkeleyDB;
use Search::InvertedIndex::Simple;
use Set::Array;

our @ISA = qw(Search::InvertedIndex::Simple);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Search::InvertedIndex::Simple::BerkeleyDB ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '1.06';

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(	# Alphabetical order.
		_dataset    => [],
		_keyset     => [],
		_lower_case => 0,
		_separator  => ',',
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

sub db_get
{
	my($self, $key) = @_;

	my(%value);

	for (sort keys %$key)
	{
		Carp::croak("Unknown key: $_") if (! $$self{'_key'}{$_});

		$$self{'_dbh'}{$_} -> db_get($$key{$_}, $value{$_});
	}

	return \%value;

}	# End of db_get.

# -----------------------------------------------

sub db_print
{
	my($self) = @_;

	my($key, @log);

	for $key (sort keys %{$$self{'_dbh'} })
	{
		my($count)  = 0;
		my($cursor) = $$self{'_dbh'}{$key} -> db_cursor();
		my($k, $v)  = ('', '');

		push @log, $key;

		while ($cursor -> c_get($k, $v, DB_NEXT) == 0)
		{
			$count++;

			push @log, "$count: $k => $v";
		}
	}

	return \@log;

}	# End of db_print.

# -----------------------------------------------

sub db_put
{
	my($self) = @_;
	my($env)  = BerkeleyDB::Env -> new
	(
		Flags => DB_PRIVATE, # Use RAM rather than disk files for the database.
	);

	for (@{$$self{'_keyset'} })
	{
		$$self{'_dbh'}{$_} = BerkeleyDB::Btree -> new
		(
			Env => $env,
		) || Carp::croak("Can't create BerkeleyDB::Btree for index $_: $!");
	}

	my($index) = $self -> build_index();

	my($primary_key, $secondary_key, $key);

	for $primary_key (sort keys %$index)
	{
		for $secondary_key (sort keys %{$$index{$primary_key} })
		{
			$key = $$self{'_lower_case'} == 0 ? $secondary_key : lc $secondary_key;

			$$self{'_dbh'}{$primary_key} -> db_put($key, join(',', $$index{$primary_key}{$secondary_key} -> print() ) );
		}
	}

}	# End of db_put.

# -----------------------------------------------

sub inflate
{
	my($self, $value) = @_;

	my($set);

	for (sort keys %$value)
	{
		if (! $$value{$_})
		{
			$set = undef;

			last;
		}

		if (! $set)
		{
			$set = Set::Array -> new(split(/$$self{'_separator'}/, $$value{$_}) );
		}
		else
		{
			$set = Set::Array -> new(join(',', $set -> intersection(Set::Array -> new(split(/$$self{'_separator'}/, $$value{$_}) ) ) ) );
		}
	}

	return $set;

}	# End of inflate.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	# There will be 1 database handle per entry in @{$$self{'_keyset'} }.
	# Also, convert keyset into a hash for ease of testing existances.

	$$self{'_dbh'}                             = {};
	@{$$self{'_key'} }{@{$$self{'_keyset'} } } = (1) x @{$$self{'_keyset'} };

	return $self;

}	# End of new.

# -----------------------------------------------

1;

__END__

=head1 NAME

Search::InvertedIndex::Simple::BerkeleyDB - Build indexes for a set of search keys; Search using BerkeleyDB

=head1 Synopsis

	my($dataset) = [
	               { # Index: 0.
		           address => 'Here',
		           event   => 'End',
		           time    => 'Time',
	               },
	               { # Index: 1.
		           address => 'Heaven',
		           event   => 'Exit',
		           time    => 'Then',
	               },
	               { # Index: 2.
		           address => 'House',
		           event   => 'Finish',
		           time    => 'Thus',
	               }
	               ];
	my($keyset)  = [qw/address time/];
	my($db)      = Search::InvertedIndex::Simple::BerkeleyDB -> new
	               (
	                   dataset => $dataset,
	                   keyset  => $keyset,
	               );

	$db -> db_put();

	my($result)	= $db -> db_get({address => 'Hea', time => 'T'}); # Returns a hashref.
	my($set)	= $db -> inflate($result);                        # Returns a Set::Array object.

	print $set ? join(',', $set -> print() ) : 'Search did not find any matching records', ". \n";

See t/test.t for a complete program.

=head1 Description

C<Search::InvertedIndex::Simple::BerkeleyDB> is a pure Perl module.

See the parent module C<Search::InvertedIndex::Simple> for an explanation of the options
C<dataset> and C<keyset> passed in to C<new()>.

C<db_put()> writes the index built by C<Search::InvertedIndex::Simple> to an in-RAM database
managed by C<BerkeleyDB>.

C<db_get($key)> returns the results of a search as a hash ref.

C<inflate($result)> converts the result hash ref into a single object of type C<Set::Array>.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns an object of type C<Search::InvertedIndex::Simple::BerkeleyDB>.

This is the class's contructor.

Parameters to C<new()>:

=over 4

=item dataset

This is an arrayref of hashrefs containing the data to be processed.

This parameter is mandatory.

=item keyset

This is an arrayref of keys used to extract values from the hashrefs in the dataset.

This parameter is mandatory.

=item lower_case

This parameter takes the values 0 and 1.

If 0, keys put into the database with db_put are not converted to lower case.

If 1, keys are converted to lower case.

Warning: You need to be careful of the case when the index generated by
C<Search::InvertedIndex::Simple> contains both upper and lower case keys,
such as 'A' and 'a'. Setting this option will convert the 'A' into 'a',
potentially creating a hard-to-find source of confusion.

The default value is 0.

This parameter is optional.

=item separator

This sets the separator used in C<inflate()> to C<split()> the values returned by the search.

See C<inflate()> below for a discussion of when to use this option.

The default value is a comma.

This parameter is optional.

=back

=head1 Method: C<db_get($key)>

The C<$key> parameter is a hashref.

The keys are some values of the C<keyset> parameter passed in to C<new()>.

The values are the strings to be searched for.

This method returns a hashref of search results.

The keys are the keys of the C<%$key> parameter passed in to C<db_get()>.

The values are either undef or the data corresponding to the search key.

If you used C<join()> to create the data values stored in the database with C<db_put()>,
consider using C<inflate()> to run C<split()> on all the results returned by C<db_get()>.

=head1 Method: C<db_print()>

This 'prints' the database by reading all records and converting all key+data pairs to strings.

The result is returned in an array ref, which you can print with:

	print map{"$_\n"} @{$db -> db_print()};

=head1 Method: C<db_put()>

This writes the index built by C<Search::InvertedIndex::Simple> to an in-RAM database
managed by C<BerkeleyDB>.

=head1 Method: C<inflate($result)>

The usual situation in which calling C<inflate()> makes sense is when you use
C<join()> to create strings of data which are then put into the database with C<db_put()>.

The C<split()> in C<inflate()> reverses the effect of the C<join()>, and
inflates the strings recovered by C<db_get()> into objects of type
C<Set::Array>, one per search key.

This C<split()> uses the separator value you passed in to C<new()>. The default separator is a comma.

C<inflate()> finds the elements of the inflated results which are common to all search keys,
by using the C<intersection()> method in the class C<Set::Array>, and returns the result
as an object of type C<Set::Array>, or undef if any search key failed to find anything.

=head1 Example code

See t/test.t for a complete program.

=head1 Author

C<Search::InvertedIndex::Simple::BerkeleyDB> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2005.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2005, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
