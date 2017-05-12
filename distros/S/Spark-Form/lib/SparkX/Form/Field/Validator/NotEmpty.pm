package SparkX::Form::Field::Validator::NotEmpty;
our $VERSION = '0.2102';


# ABSTRACT: Validates a field has some value

use Moose::Role;

has errmsg_empty => (
    isa      => 'Str',
    is       => 'rw',
    required => 0,
    default  => sub {
        my $self = shift;
        return $self->human_name .
          ' must be provided.'
    },
);

sub _not_empty {
    my ($self) = @_;

    unless ($self->value) {
        $self->error($self->errmsg_empty);
    }
    return $self;
}

after '_validate' => sub { return shift->_not_empty };

1;



=pod

=head1 NAME

SparkX::Form::Field::Validator::NotEmpty - Validates a field has some value

=head1 VERSION

version 0.2102

=head1 DESCRIPTION

A not empty enforcement mix-in. Adds one field plus action.
Makes sure that C<value> is not empty.

=head1 ACCESSORS

=head2 errmsg_empty => Str

Error message to be shown to the user if C<value> is empty.



=head1 AUTHOR

  James Laver L<http://jameslaver.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by James Laver C<< <sprintf qw(%s@%s.%s cpan jameslaver com)> >>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__END__

