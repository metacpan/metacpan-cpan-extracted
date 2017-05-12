package MooseX::Validation::Doctypes::Errors;
BEGIN {
  $MooseX::Validation::Doctypes::Errors::AUTHORITY = 'cpan:DOY';
}
{
  $MooseX::Validation::Doctypes::Errors::VERSION = '0.05';
}
use Moose;
# ABSTRACT: error class for MooseX::Validation::Doctypes

use overload '""' => 'stringify';



has errors => (
    is        => 'ro',
    predicate => 'has_errors',
);


has extra_data => (
    is        => 'ro',
    predicate => 'has_extra_data',
);


sub TO_JSON {
    my $self = shift;

    return {
        ($self->has_errors     ? (errors     => $self->errors)     : ()),
        ($self->has_extra_data ? (extra_data => $self->extra_data) : ()),
    };
}


sub stringify {
    my $self = shift;

    return join(
        "\n",
        (sort $self->_stringify_ref($self->errors)),
        $self->_stringify_extra_data($self->extra_data),
    );
}

sub _stringify_ref {
    my $self = shift;
    my ($data) = @_;

    return
        if !defined $data;

    return $data
        if !ref $data;

    return map { $self->_stringify_ref($_) } values %$data
        if ref($data) eq 'HASH';

    return map { $self->_stringify_ref($_) } @$data
        if ref($data) eq 'ARRAY';

    return "unknown data: $data";
}

sub _stringify_extra_data {
    my $self = shift;
    my ($data) = @_;

    return
        unless defined $data;

    require Data::Dumper;
    local $Data::Dumper::Terse = 1;
    my $string = Data::Dumper::Dumper($data);
    chomp($string);

    return ("extra data found:", $string);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

MooseX::Validation::Doctypes::Errors - error class for MooseX::Validation::Doctypes

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  use MooseX::Validation::Doctypes;

  doctype 'Location' => {
      id      => 'Str',
      city    => 'Str',
      state   => 'Str',
      country => 'Str',
      zipcode => 'Int',
  };

  doctype 'Person' => {
      id    => 'Str',
      name  => {
          # ... nested data structures
          first_name => 'Str',
          last_name  => 'Str',
      },
      title   => 'Str',
      # ... complex Moose types
      friends => 'ArrayRef[Person]',
      # ... using doctypes same as regular types
      address => 'Maybe[Location]',
  };

  use JSON;

  # note the lack of Location,
  # which is fine because it
  # was Maybe[Location]

  my $data = decode_json(q[
      {
          "id": "1234-A",
          "name": {
              "first_name" : "Bob",
              "last_name"  : "Smith",
           },
          "title": "CIO",
          "friends" : [],
      }
  ]);

  use Moose::Util::TypeConstraints;

  my $person = find_type_constraint('Person');
  my $errors = $person->validate($data);

  use Data::Dumper;

  warn Dumper($errors->errors)     if $errors->has_errors;
  warn Dumper($errors->extra_data) if $errors->has_extra_data;

=head1 DESCRIPTION

This class holds the errors that were found when validating a doctype. There
are two types of errors: either an existing piece of data didn't validate
against the given type constraint, or extra data was provided that wasn't
listed in the doctype. These two types correspond to the C<errors> and
C<extra_data> attributes described below.

=head1 ATTRIBUTES

=head2 errors

Returns the errors that were detected. The return value will be a data
structure with the same form as the doctype, except only leaves corresponding
to values that failed to match their corresponding type constraint. The values
will be an appropriate error message.

=head2 extra_data

Returns the extra data that was detected. The return value will be a data
structure with the same form as the incoming data, except only containing
leaves for data which was not represented in the doctype. The values will be
the values from the actual data being validated.

=head1 METHODS

=head2 has_errors

Returns true if any errors were found when validating the data against the type
constraints.

=head2 has_extra_data

Returns true if any extra data was found when comparing the data to the
doctype.

=head2 TO_JSON

Returns a hashref with keys of C<errors> and C<extra_data>, containing the
values of those attributes. This allows L<JSON> to properly encode the error
object.

=head2 stringify

Returns a human-readable string containing the error data in the object. This
is used for the stringification overload.

=head1 AUTHOR

Jesse Luehrs <doy at cpan dot org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut

