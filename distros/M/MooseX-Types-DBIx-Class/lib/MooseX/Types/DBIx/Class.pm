package MooseX::Types::DBIx::Class;
BEGIN {
  $MooseX::Types::DBIx::Class::VERSION = '0.05';
}
# ABSTRACT: MooseX::Types for DBIx::Class objects

use strict;
use warnings;

use MooseX::Types -declare => [qw(
    BaseResultSet
    BaseResultSource
    BaseRow
    BaseSchema

    ResultSet
    ResultSource
    Row
    Schema
)];

use MooseX::Types::Moose qw(Maybe Str RegexpRef ArrayRef);
use MooseX::Types::Parameterizable qw(Parameterizable);
use Moose::Util::TypeConstraints;

class_type BaseResultSet, { class => 'DBIx::Class::ResultSet' };

class_type BaseResultSource, { class => 'DBIx::Class::ResultSource' };

class_type BaseRow, { class => 'DBIx::Class::Row' };

class_type BaseSchema, { class => 'DBIx::Class::Schema' };

sub _eq_scalar_or_array {
    my($value, $other) = @_;
    return 1 if ! defined $other;
    return 1 if ! ref $other && $value eq $other;
    return 1 if ref($other) eq 'ARRAY' && grep { $value eq $_ } @$other;
    return 0;
}

subtype ResultSet,
    as Parameterizable[BaseResultSet, Maybe[ArrayRef|Str]],
    where {
        my($rs, $source_name) = @_;
        return is_BaseResultSet($rs) && _eq_scalar_or_array($rs->result_source->source_name, $source_name);
    },
    message {
        my($rs, $source_name) = @_;
        $rs ||= '';
        return sprintf(
            '%s is not a ResultSet%s',
            ( is_BaseResultSet($rs) ? 'ResultSet[' . $rs->result_source->source_name . ']' : qq('$rs') ),
            ( defined $source_name ? qq([$source_name]) : '' )
        );
    };

subtype ResultSource,
    as Parameterizable[BaseResultSource, Maybe[ArrayRef|Str]],
    where {
        my($rs, $source_name) = @_;
        return is_BaseResultSource($rs) && _eq_scalar_or_array($rs->source_name, $source_name);
    },
    message {
        my($rs, $source_name) = @_;
        $rs ||= '';
        return sprintf(
            '%s is not a ResultSource%s',
            ( is_BaseResultSource($rs) ? 'ResultSource[' . $rs->source_name . ']' : qq('$rs') ),
            ( defined $source_name ? qq([$source_name]) : '' )
        );
    };

subtype Row,
    as Parameterizable[BaseRow, Maybe[ArrayRef|Str]],
    where {
        my($row, $source_name) = @_;
        return is_BaseRow($row) && _eq_scalar_or_array($row->result_source->source_name, $source_name);
    },
    message {
        my($row, $source_name) = @_;
        $row ||= '';
        return sprintf(
            '%s is not a Row%s',
            ( is_BaseRow($row) ? 'Row[' . $row->result_source->source_name . ']' : qq('$row') ),
            ( defined $source_name ? qq([$source_name]) : '' )
        );
    };

subtype Schema,
    as Parameterizable[BaseSchema, Maybe[RegexpRef|Str]],
    where {
        my($schema, $pattern) = @_;
        return is_BaseSchema($schema) && (!$pattern || ref($schema) =~ m/$pattern/);
    },
    message {
        my($schema, $criteria) = @_;
        $schema ||= '';
        return sprintf('%s is not a Schema%s', qq('$schema'), $criteria ? qq([$criteria]) : '');
    };
1;


__END__
=pod

=head1 NAME

MooseX::Types::DBIx::Class - MooseX::Types for DBIx::Class objects

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    # in your Moose class
    use MooseX::Types::DBIx::Class qw(ResultSet Row);

    # non-parameterized usage
    has any_resultset => (
        is  => 'ro',
        isa => ResultSet
    );

    # this attribute must be a DBIx::Class::ResultSet object from your "Album" ResultSet class
    has albums_rs => (
        is  => 'ro',
        isa => ResultSet['Album']
    );

    # this attribute must be a DBIx::Class::Row object from your "Album" Result class
    has album => (
        is  => 'ro',
        isa => Row['Album']
    );

    # subtyping works as expected
    use MooseX::Types -declare => [qw(RockAlbum DecadeAlbum)];
    use Moose::Util::TypeConstraints;

    subtype RockAlbum,
        as Row['Album'],
        where { $_->genre eq 'Rock' };

    # Further parameterization!
    use MooseX::Types::Parameterizable qw(Parameterizable);

    subtype DecadeAlbum,
        as Parameterizable[Row['Album'], Str],
        where {
             my($album, $decade) = @_;
             return Row(['Album'])->check($album) && substr($album->year, -2, 1) eq substr($decade, 0, 1);
        };

    subtype EightiesRock,
        as DecadeAlbum[80],
        where { $_->genre eq 'Rock' };

    has eighties_rock_album => (
        is  => 'ro',
        isa => EightiesRock,
    );

=head1 DESCRIPTION

This simply provides some L<MooseX::Types> style types for often
shared L<DBIx::Class> objects.

=head1 TYPES

Each of the types below first ensures the appropriate C<isa>
relationship. If the (optional) parameter is specified, it constrains
the value further in some way.  These types do not define any coercions.

=over 4

=item ResultSet[$source_name]

This type constraint requires the object to be an instance of
L<DBIx::Class::ResultSet> and to have the specified C<$source_name> (if specified).

=item ResultSource[$source_name]

This type constraint requires the object to be an instance of
L<DBIx::Class::ResultSource> and to have the specified C<$source_name> (if specified).

=item Row[$source_name]

This type constraint requires the object to be an instance of
L<DBIx::Class::Row> and to have the specified C<$source_name> (if specified).

=item Schema[$class_name | qr/pattern_to_match/]

This type constraint is present mostly for completeness and requires the
object to be an instance of L<DBIx::Class::Schema> and to have a class
name that matches C<$class_name> or the regular expression if specified.

=back

=head1 BACKWARDS INCOMPATIBLE CHANGE

For any users of v0.02, you will need to replace all instances
of C<use MooseX::Types::DBIx::Class::Parameterizable> with
C<MooseX::Types::DBIx::Class>.  The usage should be identical.

=head1 AUTHORS

  Oliver Charles <oliver@ocharles.org.uk>
  Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Brian Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

