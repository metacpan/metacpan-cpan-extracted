package SQL::String;

=pod

=head1 NAME

SQL::String - An object representation of a chunk of SQL

=head1 SYNOPSIS

  <iAlias> I hate SQL::
  <iAlias> Guess what SQL::Snippit is
  <brevity> a not very useful library. I've looked at that.
  <iAlias> "A snippit of SQL"? NO! A giant complex library and storage and frameworks and junk
  <iAlias> That's all I want
  <iAlias> Every decent name I could take for a simple little tied-param chunk of SQL is taken by a "giant framework"
  <brevity> Alias: the reason is because SQL does not lend itself to small helpful modules
  <iAlias> It's like CGI all over again :)
  <rhizo> hehe
  <brevity> alias: dunno if you want to make your own big framework
  <iAlias> I have my own big framework :)
  <xantus_> heh
  <iAlias> I just want some nice little toys to clean it up a bit
  <iAlias> aha! Nobody has taken SQL::String yet
  <iAlias> It's mine I tellses you! My own... my precious...

=head1 DESCRIPTION

SQL::String is a simple object class that lets you create "chunks" of SQL
that intrinsicly have their parameters attached to them.

Quite a few standard SQL queries won't need this, you create your main
select statement once, and then provide the parameters different for each
call.

However, several types of queries can benefit from this. In particular,
the creation of large and complex search queries can be tricky to build
what might be 1000 character of SQL and keep track of all the required
parameters (short of doing them in a named form, with all the problems
of namespace management that entails).

SQL::String solves this problem by embedding the parameters into the SQL.

A SQL::String object exists as a reference to an array containing the SQL,
and a number of parameters intended to be used with it.

More usefully, SQL::String overloads concatonation so that you can still
use a SQL::String object naturally is if it was just SQL.

Once you have created your large complex query, you simple split out the
SQL and parameters parts and hand them off to DBI normally.

Although SQL::String WILL check to make sure that the SQL is a simple string
of at least one character, it makes no judgements whatsoever about the
parameters. C<undef>, references, objects, everything is legal.

This enables custom database backends that do translation of non-DBI
parameters normally.

=head2 Overloads

SQL::String objects ALWAYS evaluate as true, stringify to just the SQL,
and act properly in concatination, merging in other parameters in the
correct order as expected.

The concatination is completely interpolation-safe. That is you can do
something like the following.

  my $sql = SQL::String( 'foo = ?', 10 );
  $sql = "select * from table where $sql";

=head2 Sub-classing

Due to the nature of it's internal design, for the time being you are
forbidden to sub-class SQL::String.

There are some future issues relating to internal structure and XS
acceleration that have not been resolved.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp ();
use overload 'bool' => sub () { 1 },
             'eq'   => sub { $_[0]->[0] eq $_[1] },
             '""'   => 'sql',
             '.'    => '_concat',
             '.='   => 'concat',
             '='    => 'clone';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Constructor

=pod

=head2 new $sql [, $param, $param, $param ]

The C<new> constructor takes a fragment of SQL and zero or more parameters
and creates a new SQL::String object.

Returns a new SQL::String object, or C<undef> if the SQL argument is not a
simple (defined, non-reference, and with non-zero length) string.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $self  = (ref $_[0] eq 'ARRAY') ? shift : [ @_ ];
	defined $self->[0] and ! ref $self->[0] and CORE::length $self->[0] or return undef;
	bless $self, $class;
}

=pod

=head2 sql

The C<sql> accessor provides direct access to the SQL within the object.

=cut

sub sql { $_[0]->[0] }

=pod

=head2 params

The C<params> method returns a list of the zero or more SQL parameters.

When called in scalar context, it returns the number of parameters.

=cut

sub params {
	return $#{$_[0]} unless wantarray;
	my @params = @{$_[0]};
	shift @params;
	@params;
}

=pod

=head2 params_ref

The C<params_ref> method also returns the SQL parameters, but as a
reference to an ARRAY.

=cut

sub params_ref {
	my @params = @{$_[0]};
	shift @params;
	\@params;
}

=pod

=head2 stable

The C<stable> method can be used to double-check that the SQL::String object
contains a matching number of placeholders and parameters. At this time,
only '?' placeholders are recommended in SQL::String objects.

Returns true if the number of placeholders match the number of parameters,
or false otherwise (in the same way as the == operator).

=cut

sub stable {
	my $self         = shift;
	my $placeholders =()= $self->[0] =~ /(\?)/g;
	my $params       = $#$self;
	$placeholders == $params;
}





#####################################################################
# Overloaded Concatination

=pod

=head2 clone

Make a copy of the SQL::String object. The C<clone> function does NOT
deep copy the parameters, so you will end up with references to the
same refs if you are using refs or objects in the params list.

Returns a new and identical SQL::String object with shared param refs.

=cut

sub clone {
	my $self = shift;
	bless [ @$self ], ref $self;
}

# This is likely to be by FAR the most common operation

=pod

=head2 concat $string | \@array | $SQLString

The C<concat> method contatonates another string or SQL::String object
to the end of the current object.

It takes only a single parameter and behaves in the following way

- If passed C<undef>, throws the same warning as for a normal undef
concatonation.

- If passed a zero-length or simple string, concatonates it normally.

- If passed another SQL::String object, joins both the SQL and parameter
lists in the way you would expect, retaining the correct order of
placeholders and parameters. To make the process faster, the SQL::String
argument will be probably be destroyed in the process.

- If passed an ARRAY reference it will be treated as a SQL::String object,
with the first element as a SQL string and the rest as parameters, as with
the SQL::String parameter above.

- If passed any other type of reference of object, will die with an
appropriate error message.

In all cases, it returns the same object as a convenience.

=cut

sub concat {
	my $self  = shift;
	my $right = shift;

	# The argument is undef
	defined $right or Carp::carp('Use of uninitialized value in concatenation (.) or string') and return $self;

	# Add a plain string
	my $reftype = ref $right;
	unless ( $reftype ) {
		$self->[0] .= $right;
		return $self;
	}

	# A plain ARRAY or another SQL::String
	if ( $reftype eq 'ARRAY' or $reftype eq 'SQL::String' ) {
		$self->[0] .= shift @$right;
		push @$self, @$right;

		return $self;
	}

	# Something unknown, because we don't allow subclasses.
	Carp::croak("Tried to SQL::String::concat an illegal object ($reftype)");
}

sub _concat {
	return shift->concat(shift) unless defined $_[2];
	return shift->clone->concat(shift) unless $_[2];

	# Handle the reversed case ourselves
	my $self = shift->clone;
	my $left = shift;

	# The argument is undef
	defined $left or Carp::carp('Use of uninitialized value in concatenation (.) or string') and return $self;

	# Add a plain string
	my $reftype = ref $left;
	unless ( $reftype ) {
		$self->[0] = $left . $self->[0];
		return $self;
	}

	# A plain ARRAY (it can't be another SQL::String this time)
	if ( $reftype eq 'ARRAY' ) {
		$self->[0] = shift(@$left) . $self->[0];
		unshift @$self, @$left;
		return $self;
	}

	# Something unknown, because we don't allow subclasses.
	Carp::croak("Tried to SQL::String::concat an illegal object ($reftype)");
}

1;

### Keeping this for future uses... it was delicate and tricky to create
### $self->[0] .= ' ' unless substr($sql, 0, 1) eq ' ' or substr($self->[0], -1, 1) eq ' ';

=pod

=head1 TO DO

- Write a faster XS version?

- Change param handling to Params::Util

- Make use of bytes and potentially unicode

- Test to see if if would be better to include the params in their own
ARRAY reference.

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQL-String>

For other issues, contact the author

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Thank you to Phase N Australia (L<http://phase-n.com/>) for permitting the
open sourcing and release of this distribution.

=head1 COPYRIGHT

Copyright 2004 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
