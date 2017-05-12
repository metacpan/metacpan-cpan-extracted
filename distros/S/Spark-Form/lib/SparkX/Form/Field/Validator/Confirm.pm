package SparkX::Form::Field::Validator::Confirm;
our $VERSION = '0.2102';


# ABSTRACT: Validates whether or not the user confirmed some choice.

use Moose::Role;

has confirm => (
    isa      => 'Maybe[Str]',
    is       => 'rw',
    required => 0,
    lazy     => 1,
    default  => undef,
);

has errmsg_confirm => (
    isa      => 'Str',
    is       => 'rw',
    required => 0,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->human_name .
          ' must match ' .
          $self->_confirm_human_name
    },
);

sub _confirm_field {
    my ($self) = @_;

    return $self->form->get($self->confirm);
}

sub _confirm_human_name {
    my ($self) = @_;

    return $self->_confirm_field->human_name;
}

sub _confirm {
    my ($self) = @_;

    return unless $self->confirm;

    if ($self->value ne $self->_confirm_field->value) {
        $self->error($self->errmsg_confirm);
    }
    return $self;
}

after '_validate' => sub { return shift->_confirm };


1;



=pod

=head1 NAME

SparkX::Form::Field::Validator::Confirm - Validates whether or not the user confirmed some choice.

=head1 VERSION

version 0.2102

=head1 DESCRIPTION

A confirmation comparison mix-in. Adds two fields plus action.
Makes sure that the selected C<confirm> field matches this one.

=head1 ACCESSORS

=head2 confirm => Str

Name of the field whose value must match.
Required, no default.

=head2 errmsg_confirm => Str

Allows you to provide a custom error message for when the fields do not match.
Optional, Default = $human_name must match $confirm_human_name



=head1 AUTHOR

  James Laver L<http://jameslaver.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by James Laver C<< <sprintf qw(%s@%s.%s cpan jameslaver com)> >>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__END__

