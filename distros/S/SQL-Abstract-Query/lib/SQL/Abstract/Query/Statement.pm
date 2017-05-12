package SQL::Abstract::Query::Statement;
{
  $SQL::Abstract::Query::Statement::VERSION = '0.03';
}
use Moose::Role;

=head1 NAME

SQL::Abstract::Query::Statement - A role providing base functionality for statement objects.

=head1 DESCRIPTION

This role contains the shared functionality for the various
statement classes.  Much of this module contains low-level pieces
that the normal user will not need to access directly (and probably
shouldn't).

The exceptions to this are the sql() attribute and the values()
method, which should be used extensively by users of the query
classes.

=cut

requires(qw( _build_positional_args _build_abstract_result ));

use List::MoreUtils qw( zip );
use Moose::Util::TypeConstraints;
use MooseX::ClassAttribute;
use Carp qw( croak );

=head1 CONSTRUCTOR

    my $statement = SQL::Abstract::Query::SomeClass->new( %named_args );
    my $statement = SQL::Abstract::Query::SomeClass->new( $query, @arg_values );
    my $statement = SQL::Abstract::Query::SomeClass->new( $query, @arg_values, \%extra_args );

New statement objects may be created by passing arguments to new() as either named values (a
hash or hashref of name/value pairs as is typical) or as positional values.

When passing arguments as positional values the first argument must be an instance of
L<SQL::Abstract::Query>.  The rest of the arguments will be named using the
L</positional_args> static attribute which is declared by each statement class.  A
final hashref argument of extra arguments may be passed.  All of the positional and
extra arguments will be combined and used to instantiate the object.

=cut

around 'BUILDARGS' => sub{
    my $orig  = shift;
    my $class = shift;

    if (@_ and ref($_[0])) {
        my $args = { query => shift };
        my $arg_names = $class->positional_args();

        foreach my $name (@$arg_names) {
            my $value = shift;
            next if !defined $value;
            $args->{ $name } = $value;
        }

        my $extra_args = shift;
        if (defined $extra_args) {
            if (ref($extra_args) ne 'HASH') {
                croak 'Extra arguments were passed but they are not a hashref';
            }

            foreach my $name (keys %$extra_args) {
                $args->{ $name } = $extra_args->{ $name };
            }
        }

        return $class->$orig( $args );
    }

    return $class->$orig( @_ );
};

=head1 TYPES

All of these type names are prefixed with "SQL::Abstract::Query::Types::".

=head2 Table

The name of a table.  Currently there are no restrictions on
this type except that it must be a plain string.

=cut

subtype 'SQL::Abstract::Query::Types::Table',
    as 'Str';

=head2 FieldValues

A hashref of name/value pairs where the names are column names
and the values are the column values to be set.  This type may
also be passed as an arrayref which will be coerced and turned
in to a hashref where the values equal the keys.

=cut

subtype 'SQL::Abstract::Query::Types::FieldValues',
    as 'HashRef';

coerce 'SQL::Abstract::Query::Types::FieldValues',
    from 'ArrayRef',
    via { return { zip( @$_, @$_ ) } };

=head2 Where

The where clause.  Must be a hashref, arrayref, or a plain string.

=cut

subtype 'SQL::Abstract::Query::Types::Where',
    as 'HashRef|ArrayRef|Str';

=head1 ARGUMENTS

=head2 query

The L<SQL::Abstract::Query> object that was used to generate this
particular query object.

=cut

has query => (
    is       => 'ro',
    isa      => 'SQL::Abstract::Query',
    required => 1,
);

=head1 ATTRIBUTES

=head2 abstract_result

This attribute contains the results of calling the underlying
L<SQL::Abstract> method plus any modifications that the query
object makes.  A query class must provide a builder method of
the name _build_abstract_result() which is expected to return
an array reference where the first entry is the SQL and the
remaining entries are the bind values.

The SQL will provide the value for the sql() attribute and the
bind values will provide the values for the original_values()
attribute.

Typically you will have no need to access this attribute directly
and instead should use the sql() attribute and the values() method.

=cut

has abstract_result => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
    init_arg   => undef,
);

=head2 original_values

The bind values that were returned by the original construction of
the abstract_result() attribute.  Typically you will not need to
access this directly.

=cut

sub original_values {
    my ($self) = @_;
    return @{ $self->_original_values() };
}

has _original_values => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
    init_arg   => undef,
);
sub _build__original_values {
    my ($self) = @_;
    my @values = @{ $self->abstract_result() };
    shift( @values );
    return \@values;
}

=head2 sql

    my $sql = $statement->sql();

This read-only attribute returns the SQL that was generated
for the query.

=cut

has sql => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
    init_arg   => undef,
);
sub _build_sql {
    my ($self) = @_;
    return $self->abstract_result->[0];
}

=head1 STATIC ATTRIBUTES

=head2 positional_args

When L</CONSTRUCTOR> is called with positional arguments, rather than named arguments,
this attribute is used to determine which value should be assigned to which
argument.  Each statement class must provide a _build_positional_args() method
that returns an arrayref of argument names.

=cut

class_has positional_args => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
    init_arg   => undef,
);

=head1 METHODS

=head2 values

    my @bind_values = $statement->values( \%field_values );

Given a hash ref of field name/value pairs this will return the
values in the order in which they appear in the SQL.

=cut

sub values {
    my ($self, $field_values) = @_;

    my @values;
    foreach my $value ($self->original_values()) {
        push @values, $field_values->{$value};
    }

    return @values;
}

=head2 quote

This is a shortcut to calling $query->abstract->_quote().

=cut

sub quote {
    my $self = shift;
    return $self->query->abstract->_quote( @_ );
}

=head1 STATIC METHODS

=head2 call

This method is called by L<SQL::Abstract::Query> to provide the
procedural interface to queries.  Typically you will not want to
call this directly.

All arguments are passed straight on to the L</CONSTRUCTOR>.

Returns a list containing the generated SQL and bind values.

=cut

sub call {
    my $class = shift;

    my $self = $class->new( @_ );

    return(
        $self->sql(),
        $self->original_values(),
    );
}

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

