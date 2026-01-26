####################################################################
#
#     This file was generated using XDR::Parse version v1.0.1
#                   and LibVirt version v12.0.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################


use v5.14.1;
use warnings;
use Syntax::Operator::Elem qw( elem_str );

package Protocol::Sys::Virt::TypedParams v12.0.6;


use Carp qw(croak);
use Exporter 'import';
use Log::Any qw($log);

# copied from Protocol::Sys::Virt::Remote::XDR, with VIR_ prefix stripped
use constant {
    TYPED_PARAM_INT     => 1,
    TYPED_PARAM_UINT    => 2,
    TYPED_PARAM_LLONG   => 3,
    TYPED_PARAM_ULLONG  => 4,
    TYPED_PARAM_DOUBLE  => 5,
    TYPED_PARAM_BOOLEAN => 6,
    TYPED_PARAM_STRING  => 7,
};

my %value_field_name = (
    1 => 'i',
    2 => 'ui',
    3 => 'l',
    4 => 'ul',
    5 => 'd',
    6 => 'b',
    7 => 's'
    );


our @EXPORT = qw(
    typed_params_new
    typed_field_new
    typed_value_new

    typed_params_check_fields_only
    typed_params_field
    typed_params_fields

    typed_params_field_int_value
    typed_params_field_uint_value
    typed_params_field_long_value
    typed_params_field_ulong_value
    typed_params_field_double_value
    typed_params_field_boolean_value
    typed_params_field_string_value

    TYPED_PARAM_INT
    TYPED_PARAM_UINT
    TYPED_PARAM_LLONG
    TYPED_PARAM_ULLONG
    TYPED_PARAM_DOUBLE
    TYPED_PARAM_BOOLEAN
    TYPED_PARAM_STRING

    );


sub typed_params_check_fields_only {
    my ( $params, @fields ) = @_;

    for my $param (@{ $params }) {
        unless (elem_str( $param->{field}, @fields )) {
            croak "Unexpected parameter $param->{field}";
        }
    }
    return 1;
}

sub typed_params_field {
    my ( $params, $name, @rest ) = @_;
    return unless $params;

    for my $param (@{ $params }) {
        next unless $param->{field} eq $name;

        if (@rest) {
            my $new_entry = shift @rest;
            $param = { field => $name, value => $new_entry };
            return $param;
        }
        return $param;
    }
    if (@rest) {
        my $new_entry = shift @rest;
        my $param = { field => $name, value => $new_entry };
        push @{ $params }, $param;
        return $param;
    }
    return undef;
}

sub typed_params_fields {
    my ( $params, $name ) = @_;
    return [ grep { $_->{field} eq $name } @{ $params } ];
}

sub typed_value_new {
    my ( $type, $value ) = @_;
    return { type => $type, $value_field_name{$type} => $value };
}

sub typed_field_new {
    my ( $name, $value ) = @_;
    return { field => $name, value => $value };
}

sub typed_params_new {
    my ( $from ) = @_;
    $from = [] unless $from;

    return [ map { { %{ $_ } } } @{ $from } ];
}

sub _typed_params_field_value {
    my ( $params, $name, $type, @rest ) = @_;
    return unless $params;

    for my $param (@{ $params }) {
        next unless $param->{field} eq $name;
        croak "TypedParam type mismatch: expected $type, found $param->{value}->{type}"
            if $type != $param->{value}->{type};

        if (@rest) {
            my $new_value = shift @rest;
            $param = {
                field => $name,
                value => {
                    type => $type,
                    $value_field_name{$type} => $new_value }
            };
            return $new_value;
        }

        return $param->{value}->{$value_field_name{$type}};
    }

    if (@rest) {
        my $new_value = shift @rest;
        push @{ $params }, {
            field => $name,
            value => {
                type => $type,
                $value_field_name{$type} => $new_value }
        };

        return $new_value;
    }

    return undef;
}

sub typed_params_field_int_value {
    my ( $params, $name, @rest ) = @_;
    return _typed_params_field_value( $params, $name, TYPED_PARAM_INT, @rest );
}

sub typed_params_field_uint_value {
    my ( $params, $name, @rest ) = @_;
    return _typed_params_field_value( $params, $name, TYPED_PARAM_UINT, @rest );
}

sub typed_params_field_long_value {
    my ( $params, $name, @rest ) = @_;
    return _typed_params_field_value( $params, $name, TYPED_PARAM_LLONG, @rest );
}

sub typed_params_field_ulong_value {
    my ( $params, $name, @rest ) = @_;
    return _typed_params_field_value( $params, $name, TYPED_PARAM_ULLONG, @rest );
}

sub typed_params_field_double_value {
    my ( $params, $name, @rest ) = @_;
    return _typed_params_field_value( $params, $name, TYPED_PARAM_DOUBLE, @rest );
}

sub typed_params_field_boolean_value {
    my ( $params, $name, @rest ) = @_;
    return _typed_params_field_value( $params, $name, TYPED_PARAM_BOOLEAN, @rest );
}

sub typed_params_field_string_value {
    my ( $params, $name, @rest ) = @_;
    return _typed_params_field_value( $params, $name, TYPED_PARAM_STRING, @rest );
}



1;

__END__

=head1 NAME

Protocol::Sys::Virt::TypedParams - Helper routines for typed parameter values

=head1 VERSION

v12.0.6

=head1 SYNOPSYS

  my $params = typed_params_new();
  typed_params_field( $params, MIGRATE_PARAM_DEST_NAME,
                      typed_value_new( TYPED_PARAM_STRING, 'test' ) );

  my $dest = typed_params_field_string_value( $params, MIGRATE_PARAM_DEST_NAME );

=head1 DESCRIPTION

Typed parameters and typed parameter sets are part of the LibVirt protocol.
This module offers a set of functions to work with typed parameters and
parameter sets.

=head1 CONSTANTS

=head2 TYPED_PARAM_*

=over 8

=item * TYPED_PARAM_INT

Integer (32-bit) value parameter

=item * TYPED_PARAM_UINT

Unsigned integer value parameter

=item * TYPED_PARAM_LLONG

Long long (64-bit) integer value parameter

=item * TYPED_PARAM_ULLONG

Unsigned long long integer value parameter

=item * TYPED_PARAM_DOUBLE

IEEE double float value parameter

=item * TYPED_PARAM_BOOLEAN

Boolean value parameter

=item * TYPED_PARAM_STRING

String value parameter; servers need to indicate
feature DRV_FEATURE_TYPED_PARAM_STRING to accept
this type of parameter

=back

=head1 FUNCTIONS

=head2 typed_params_new

  my $new_params = typed_params_new();

  # - or -
  my $new_params = typed_params_new( $old_params );

Creates and returns a new typed parameter set. If C<$old_params> is passed,
the structure is duplicated to create the return value.

=head2 typed_field_new

  my $new_field = typed_field_new( 'name', TYPED_PARAM_INT, 3 );

Creates a new typed parameter field to become an entry in a typed
parameter set.

=head2 typed_value_new

  my $value = typed_value_new( $type, $value );

Creates and returns a new typed value.

=head2 typed_params_field

  my $field = typed_params_field( $params, $name );

  # - or -
  typed_params_field( $params, $name, $typed_value );

When invoked as getter, returns the first field named C<$name> in the
parameter set. When invoked as a setter, changes the value of the first
named field to the value provided, or, if no matching field is found,
adds a field by this name to the parameter set.

=head2 typed_params_fields

  my $fields = typed_params_fields( $params, $fieldname );

Returns all fields in the parameter set whose name matches C<$fieldname>.

=head2 typed_params_check_fields_only

  my $bool = typed_params_check_fields_only( $params, $fieldname1, $fieldname2, ... );

Returns true when there are no other parameters than with the field names
passed in the arguments list.

On failure, throws an error.

=head2 typed_params_field_int_value

  my $value = typed_params_field_int_value( $params, $fieldname );

  # - or -
  typed_params_field_int_value( $params, $fieldname, $value );

When invoked as a getter, returns the value of the first parameter in
C<$params> whose name matches C<$fieldname>. When invoked as a setter,
sets the value of the first parameter in C<$params> whose name matches
C<$fieldname> to C<$value>, or, when no such entry exists, adds a
parameter by this name and value.

When the entry exists, but has a different type, an error is thrown.

=head2 typed_params_field_uint_value

  my $value = typed_params_field_uint_value( $params, $fieldname );

  # - or -
  typed_params_field_uint_value( $params, $fieldname, $value );

When invoked as a getter, returns the value of the first parameter in
C<$params> whose name matches C<$fieldname>. When invoked as a setter,
sets the value of the first parameter in C<$params> whose name matches
C<$fieldname> to C<$value>, or, when no such entry exists, adds a
parameter by this name and value.

When the entry exists, but has a different type, an error is thrown.

=head2 typed_params_field_long_value

  my $value = typed_params_field_long_value( $params, $fieldname );

  # - or -
  typed_params_field_long_value( $params, $fieldname, $value );

When invoked as a getter, returns the value of the first parameter in
C<$params> whose name matches C<$fieldname>. When invoked as a setter,
sets the value of the first parameter in C<$params> whose name matches
C<$fieldname> to C<$value>, or, when no such entry exists, adds a
parameter by this name and value.

When the entry exists, but has a different type, an error is thrown.

=head2 typed_params_field_ulong_value

  my $value = typed_params_field_ulong_value( $params, $fieldname );

  # - or -
  typed_params_field_ulong_value( $params, $fieldname, $value );

When invoked as a getter, returns the value of the first parameter in
C<$params> whose name matches C<$fieldname>. When invoked as a setter,
sets the value of the first parameter in C<$params> whose name matches
C<$fieldname> to C<$value>, or, when no such entry exists, adds a
parameter by this name and value.

When the entry exists, but has a different type, an error is thrown.

=head2 typed_params_field_double_value

  my $value = typed_params_field_double_value( $params, $fieldname );

  # - or -
  typed_params_field_double_value( $params, $fieldname, $value );

When invoked as a getter, returns the value of the first parameter in
C<$params> whose name matches C<$fieldname>. When invoked as a setter,
sets the value of the first parameter in C<$params> whose name matches
C<$fieldname> to C<$value>, or, when no such entry exists, adds a
parameter by this name and value.

When the entry exists, but has a different type, an error is thrown.

=head2 typed_params_field_boolean_value

  my $value = typed_params_field_boolean_value( $params, $fieldname );

  # - or -
  typed_params_field_boolean_value( $params, $fieldname, $value );

When invoked as a getter, returns the value of the first parameter in
C<$params> whose name matches C<$fieldname>. When invoked as a setter,
sets the value of the first parameter in C<$params> whose name matches
C<$fieldname> to C<$value>, or, when no such entry exists, adds a
parameter by this name and value.

When the entry exists, but has a different type, an error is thrown.

=head2 typed_params_field_string_value

  my $value = typed_params_field_string_value( $params, $fieldname );

  # - or -
  typed_params_field_string_value( $params, $fieldname, $value );

When invoked as a getter, returns the value of the first parameter in
C<$params> whose name matches C<$fieldname>. When invoked as a setter,
sets the value of the first parameter in C<$params> whose name matches
C<$fieldname> to C<$value>, or, when no such entry exists, adds a
parameter by this name and value.

When the entry exists, but has a different type, an error is thrown.

Note that C<TYPED_PARAM_STRING> typed parameters can only be sent to servers
declaring support for C<DRV_FEATURE_TYPED_PARAM_STRING>.

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT

See the LICENSE file in this distribution.

