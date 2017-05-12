package SQL::Script;

=pod

=head1 NAME

SQL::Script - An object representing a series of SQL statements, normally
stored in a file

=head1 PREAMBLE

For far too long we have been throwing SQL scripts at standalone binary
clients, it's about time we had some way to throw them at the DBI instead.

Since I'm sick and tired of waiting for someone that knows more about SQL
than me to do it properly, I shall implement it myself, and wait for said
people to send me patches to fix anything I do wrong.

At least this way I know the API will be done in a usable way.

=head1 DESCRIPTION

This module provides a very simple and straight forward way to work with a
file or string that contains a series of SQL statements.

In essense, all this module really does is slurp in a file and split it
by semi-colon+newline.

However, by providing an initial data object and API for this function, my
hope is that as more people use this module, better mechanisms can be
implemented underneath the same API at a later date to read and split the
script in a more thorough and complete way.

It may well become the case that SQL::Script acts as a front end for a whole
quite of format-specific SQL splitters.

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp         ();
use Params::Util qw{ _STRING _SCALAR _INSTANCE };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.06';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  # Default naive split
  $script = SQL::Script->new;
  
  # Custom split (string)
  $script = SQL::Script->new( split_by => "\n\n;" );
  
  # Custom split (regexp)
  $script = SQL::Script->new( split_by => qr/\n\n;/ );
  
  # Create a script object from pre-split statements
  $script = SQL::Script->new( statements => \@sql );

The C<new> constructor create a new SQL script object, containing zero statements.

It takes a single option param or C<split_by> which can be either a string
or regexp by which to split the SQL.

Returns a new B<SQL::String> object, or throws an exception on error.

=cut
  
sub new {
	my $class = shift;
	my $self  = bless { statements => [], @_ }, $class;

	# Check and apply default params
	unless ( $self->split_by ) {
		$self->{split_by} = ";\n";
	}
	unless ( _STRING($self->split_by) or ref($self->split_by) eq 'Regexp' ) {
		Carp::croak("Missing or invalid split_by param");
	}

	return $self;
}

=pod

=head2 read

  # Read a SQL script from one of several sources
  $script->read( 'filename.sql' );
  $script->read( \$sql_string   );
  $script->read( $io_handle     );

The C<read> method is used to read SQL from an input source (which can
be provided as either a file name, a reference to a SCALAR containing the
SQL, or as an IO handle) and split it into a set of statements.

If the B<SQL::Script> object already contains a set of statements, they will
be overwritten and replaced.

Returns true on success, or throw an exception on error.

=cut

sub read {
	my $self  = shift;
	my $input = _INPUT_SCALAR(shift) or Carp::croak("Missing or invalid param to read");
	$self->{statements} = $self->split_sql( $input );
	return 1;
}

=pod

=head2 split_by

The C<split_by> accessor returns the string or regexp that will be used to
split the SQL into statements.

=cut

sub split_by {
	$_[0]->{split_by};
}

=pod

=head2 statements

In list context, the C<statements> method returns a list of all the
individual statements for the script.

In scalar context, it returns the number of statements.

=cut

sub statements {
	if ( wantarray ) {
		return @{$_[0]->{statements}};
	} else {
		return scalar @{$_[0]->{statements}};
	}
}





#####################################################################
# Main Methods

=pod

=head2 split_sql

The C<split_sql> method takes a reference to a SCALAR containing a string
of SQL statements, and splits it into the separate statements, returning
them as a reference to an ARRAY, or throwing an exception on error.

This method does NOT update the internal state, it simply applies the
appropriate parsing rules.

=cut

sub split_sql {
	my $self = shift;
	my $sql  = _SCALAR(shift) or Carp::croak("Did not pass a SCALAR ref to split_sql");

	# Find the regex to split by
	my $regexp;
	if ( _STRING($self->split_by) ) {
		$regexp = quotemeta $self->split_by;
		$regexp = qr/$regexp/;
	} elsif ( ref($self->split_by) eq 'Regexp' ) {
		$regexp = $self->split_by;
	} else {
		Carp::croak("Unknown or unsupported split_by value");
	}

	# Split the sql, clean up and remove empty ones
	my @statements = grep { /\S/ } split( $regexp, $$sql );
	foreach ( @statements ) {
		s/^\s+//;
		s/\s+$//;
	}

	return \@statements;
}

=pod

=head2 run

The C<run> method executes the SQL statements in the script object.

Returns true if ALL queries are executed successfully, or C<undef> on error.

(These return values may be changed in future, probably to a style where all
the successfully executed queries are returned, and the object throws an
exception on error)

=cut

sub run {
	my $self = shift;
	my $dbh  = _INSTANCE(shift, 'DBI::db') or Carp::croak("Did not provide DBI handle to run");

	# Execute each of the statements
	foreach my $sql ( $self->statements ) {
		$dbh->do($sql) or return undef;
	}
	return 1;
}





#####################################################################
# Support Functions

sub _INPUT_SCALAR {
	unless ( defined $_[0] ) {
		return undef;
	}
	unless ( ref $_[0] ) {
		unless ( -f $_[0] and -r _ ) {
			return undef;
		}
		local $/ = undef;
		open( my $file, '<', $_[0] )  or return undef;
		defined(my $buffer = <$file>) or return undef;
		close( $file )                or return undef;
		return \$buffer;
	}
	if ( _SCALAR($_[0]) ) {
		return shift;
	}
	if ( _HANDLE($_[0]) ) {
		local $/ = undef;
		my $buffer = <$_[0]>;
		return \$buffer;
	}
	return undef;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQL-Script>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
