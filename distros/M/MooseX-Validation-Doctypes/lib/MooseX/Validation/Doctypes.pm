package MooseX::Validation::Doctypes;
BEGIN {
  $MooseX::Validation::Doctypes::AUTHORITY = 'cpan:DOY';
}
{
  $MooseX::Validation::Doctypes::VERSION = '0.05';
}
use strict;
use warnings;
# ABSTRACT: validation of nested data structures with Moose type constraints

use MooseX::Meta::TypeConstraint::Doctype;

use Sub::Exporter -setup => {
    exports => ['doctype', 'maybe_doctype'],
    groups => {
        default => ['doctype', 'maybe_doctype'],
    },
};



sub doctype {
    my $name;
    $name = shift if @_ > 1;

    my ($doctype) = @_;

    # XXX validate name

    my $args = {
        ($name ? (name => $name) : ()),
        doctype            => $doctype,
        package_defined_in => scalar(caller),
    };

    my $tc = MooseX::Meta::TypeConstraint::Doctype->new($args);
    Moose::Util::TypeConstraints::register_type_constraint($tc)
        if $name;

    return $tc;
}


sub maybe_doctype {
    my $name;
    $name = shift if @_ > 1;

    my ($doctype) = @_;

    # XXX validate name

    my $args = {
        ($name ? (name => $name) : ()),
        doctype            => $doctype,
        package_defined_in => scalar(caller),
        maybe              => 1,
    };

    my $tc = MooseX::Meta::TypeConstraint::Doctype->new($args);
    Moose::Util::TypeConstraints::register_type_constraint($tc)
        if $name;

    return $tc;
}


1;

__END__
=pod

=head1 NAME

MooseX::Validation::Doctypes - validation of nested data structures with Moose type constraints

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

NOTE: The API for this module is still in flux as I try to decide on how it should work. You have been warned!

This module allows you to declare L<Moose> type constraints to validate nested
data structures as you may get back from a JSON web service or something along
those lines. The doctype declaration can be any arbitrarily nested structure of
hashrefs and arrayrefs, and will be used to validate a data structure which has
that same form. The leaf values in the doctype should be Moose type
constraints, which will be used to validate the leaf nodes in the given data
structure.

=head1 FUNCTIONS

=head2 doctype $name, $doctype

Declares a new doctype type constraint. C<$name> is optional, and if it is not
given, an anonymous type constraint is created instead.

=head2 maybe_doctype $name, $doctype

Identical to C<doctype>, except that undefined values are also allowed. This is
useful when nesting doctypes, as in:

  doctype 'Person' => {
      id      => 'Str',
      name    => maybe_doctype({
          first => 'Str',
          last  => 'Str',
      }),
      address => 'Str',
  };

This way, C<< { first => 'Bob', last => 'Smith' } >> is a valid name, and it's
also valid to not provide a name, but an invalid name will still throw an
error.

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-moosex-validation-doctypes at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Validation-Doctypes>.

=head1 SEE ALSO

L<Moose::Meta::TypeConstraint>

L<MooseX::Types::Structured>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc MooseX::Validation::Doctypes

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Validation-Doctypes>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Validation-Doctypes>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Validation-Doctypes>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Validation-Doctypes>

=back

=head1 AUTHOR

Jesse Luehrs <doy at cpan dot org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut

