package Spark::Form::Field;
our $VERSION = '0.2102';


# ABSTRACT: Superclass for all Form Fields

use Moose;
use MooseX::AttributeHelpers;
use MooseX::LazyRequire;

with qw(MooseX::Clone);

has name => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has form => (
    isa      => 'Spark::Form',
    is       => 'rw',
    lazy_required => 1,
    weak_ref => 1, #De-circular-ref
    traits => [qw(NoClone)], #Argh, what will it be set to?
);

has value => (
    is       => 'rw',
    required => 0,
);

has valid => (
    isa      => 'Bool',
    is       => 'rw',
    required => 0,
    default  => 0,
);

has _errors => (
    metaclass => 'Collection::Array',
    isa       => 'ArrayRef[Str]',
    is        => 'ro',
    required  => 0,
    default   => sub { [] },
    provides  => {
        push     => '_add_error',
        elements => 'errors',
        clear    => '_clear_errors',
    },
);

sub error {
    my ($self, $error) = @_;

    $self->valid(0);
    $self->_add_error($error);

    return $self;
}

sub human_name {
    my ($self) = @_;

    if ($self->can('label')) {
        return $self->label if $self->label;
    }
    if ($self->can('name')) {
        return $self->name if $self->name;
    }
    return q();
}

sub validate {
    my ($self) = @_;
    $self->_clear_errors;
    $self->valid(1);

    #Set a default of the empty string, suppresses a warning
    $self->value($self->value || q());
    return $self->_validate;
}

sub _validate { return 1 }

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Spark::Form::Field - Superclass for all Form Fields

=head1 VERSION

version 0.2102

=head1 DESCRIPTION

Field superclass. Must subclass this to be considered a field.

=head1 SYNOPSIS

 package My::Field;
 use Moose;
 require Spark::Form::Field;
 extends 'Spark::Form::Field';
 with 'Spark::Form::Field::Role::Validateable';
 with 'Spark::Form::Field::Role::Printable::XHTML';

 sub _validate {
     my $self = shift;

     #validate existence of data
     if ($self->value) {
         #If we're valid, we should say so
         $self->valid(1);
     } else {
         #error will call $self->valid(0) and also set an error.
         $self->error('no value')
     }

     #And we should return boolean validity
     $self->valid
 }

 sub to_xhtml {
     #Rather poorly construct an XHTML tag
     '<input type="checkbox" value="' . shift-value . '">';
 }

Note that you might want to look into HTML::Tiny.
Or better still, L<SparkX::Form::Field::Plugin::StarML>.

There are a bunch of pre-built fields you can actually use in
L<SparkX::Form::BasicFields>.

=head1 ACCESSORS

=head2 name => Str

Name of the field in the data source. Will be slurped on demand.
Required at validation time, not at construction time.

=head2 form => Spark::Form

Reference to the form it is a member of.

=head2 value => Any

Value in the field.

=head2 valid => Bool

Treat as read-only. Whether the field is valid.

=head2 errors => ArrayRef

Treat as read-only. The list of errors generated in validation.

=head1 METHODS

=head2 human_name

Returns the label if present, else the field name.

=head2 validate

Returns true always. Subclass and fill in C<_validate> to do proper validation. See the synopsis.

=head2 error (Str)

Adds an error to the current field's list.

=head1 SEE ALSO

=over 4

=item L<Spark::Form::Field::Role::Printable> - Fields that can be printed

=item L<SparkX::Form::BasicValidators> - Set of validators to use creating fields

=item L<SparkX::Form::BasicFields> - Ready to use fields

=back 



=head1 AUTHOR

  James Laver L<http://jameslaver.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by James Laver C<< <sprintf qw(%s@%s.%s cpan jameslaver com)> >>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__END__

