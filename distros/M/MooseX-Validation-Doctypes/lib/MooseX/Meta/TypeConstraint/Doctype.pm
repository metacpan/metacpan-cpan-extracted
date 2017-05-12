package MooseX::Meta::TypeConstraint::Doctype;
BEGIN {
  $MooseX::Meta::TypeConstraint::Doctype::AUTHORITY = 'cpan:DOY';
}
{
  $MooseX::Meta::TypeConstraint::Doctype::VERSION = '0.05';
}
use Moose;
# ABSTRACT: Moose type constraint for validating doctypes

use Devel::PartialDump 'dump';
use Moose::Util::TypeConstraints qw(class_type find_type_constraint
                                    match_on_type);
use Scalar::Util 'weaken';

use MooseX::Validation::Doctypes::Errors;


extends 'Moose::Meta::TypeConstraint';

class_type('Moose::Meta::TypeConstraint');


has doctype => (
    is       => 'ro',
    isa      => 'Ref',
    required => 1,
);

has maybe => (
    is  => 'ro',
    isa => 'Bool',
);

has '+parent' => (
    default => sub { find_type_constraint('Ref') },
);

has '+constraint' => (
    lazy    => 1,
    default => sub {
        weaken(my $self = shift);
        return sub { !$self->_validate_doctype($_) };
    },
);

has '+message' => (
    default => sub {
        weaken(my $self = shift);
        return sub { $self->_validate_doctype($_) };
    },
);

sub _validate_doctype {
    my $self = shift;
    my ($data, $doctype, $prefix) = @_;

    $doctype = $self->doctype
        unless defined $doctype;
    $prefix = ''
        unless defined $prefix;

    my ($errors, $extra_data);

    match_on_type $doctype => (
        'HashRef' => sub {
            if ($self->maybe && !defined($data)) {
                # ignore it
            }
            elsif (!find_type_constraint('HashRef')->check($data)) {
                $errors = $self->_format_error($data, $prefix);
            }
            else {
                for my $key (keys %$doctype) {
                    my $sub_errors = $self->_validate_doctype(
                        $data->{$key},
                        $doctype->{$key},
                        join('.', (length($prefix) ? $prefix : ()), $key)
                    );
                    if ($sub_errors) {
                        if ($sub_errors->has_errors) {
                            $errors ||= {};
                            $errors->{$key} = $sub_errors->errors;
                        }
                        if ($sub_errors->has_extra_data) {
                            $extra_data ||= {};
                            $extra_data->{$key} = $sub_errors->extra_data;
                        }
                    }
                }
                for my $key (keys %$data) {
                    if (!exists $doctype->{$key}) {
                        $extra_data ||= {};
                        $extra_data->{$key} = $data->{$key};
                    }
                }
            }
        },
        'ArrayRef' => sub {
            if ($self->maybe && !defined($data)) {
                # ignore it
            }
            elsif (!find_type_constraint('ArrayRef')->check($data)) {
                $errors = $self->_format_error($data, $prefix);
            }
            else {
                for my $i (0..$#$doctype) {
                    my $sub_errors = $self->_validate_doctype(
                        $data->[$i],
                        $doctype->[$i],
                        join('.', (length($prefix) ? $prefix : ()), "[$i]")
                    );
                    if ($sub_errors) {
                        if ($sub_errors->has_errors) {
                            $errors ||= [];
                            $errors->[$i] = $sub_errors->errors;
                        }
                        if ($sub_errors->has_extra_data) {
                            $extra_data ||= [];
                            $extra_data->[$i] = $sub_errors->extra_data;
                        }
                    }
                }
                for my $i (0..$#$data) {
                    next if $i < @$doctype;
                    $extra_data ||= [];
                    $extra_data->[$i] = $data->[$i];
                }
            }
        },
        'Str|Moose::Meta::TypeConstraint' => sub {
            my $tc = Moose::Util::TypeConstraints::find_or_parse_type_constraint($doctype);
            die "Unknown type $doctype" unless $tc;
            if ($tc->isa(__PACKAGE__)) {
                my $sub_errors = $tc->_validate_doctype($data, undef, $prefix);
                if ($sub_errors) {
                    $errors = $sub_errors->errors;
                    $extra_data = $sub_errors->extra_data;
                }
            }
            elsif (!$tc->check($data)) {
                $errors = $self->_format_error($data, $prefix);
            }
        },
        => sub {
            die "Unknown doctype at position '$prefix': " . dump($doctype);
        },
    );

    return unless $errors || $extra_data;

    return MooseX::Validation::Doctypes::Errors->new(
        ($errors     ? (errors     => $errors)     : ()),
        ($extra_data ? (extra_data => $extra_data) : ()),
    );
}

sub _format_error {
    my $self = shift;
    my ($data, $prefix) = @_;

    return "invalid value " . dump($data) . " for '$prefix'";
}

no Moose;

1;

__END__
=pod

=head1 NAME

MooseX::Meta::TypeConstraint::Doctype - Moose type constraint for validating doctypes

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
  die "Data is invalid" unless $person->check($data);

=head1 DESCRIPTION

This module implements the actual type constraint that is created by the
C<doctype> function in L<MooseX::Validation::Doctypes>. It is a subclass of
L<Moose::Meta::TypeConstraint> which adds a required C<doctype> parameter, and
automatically generates a constraint and message which validate based on that
doctype (as described in the MooseX::Validation::Doctypes docs).

=head1 ATTRIBUTES

=head2 doctype

The doctype to validate. Required.

=head1 AUTHOR

Jesse Luehrs <doy at cpan dot org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut

