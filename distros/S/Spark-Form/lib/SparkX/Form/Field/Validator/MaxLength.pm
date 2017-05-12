package SparkX::Form::Field::Validator::MaxLength;
our $VERSION = '0.2102';


# ABSTRACT: Validates a variable does not exceed a given size

use Moose::Role;

has max_length => (
    isa      => 'Maybe[Int]',
    is       => 'rw',
    required => 0,
    default  => 0,
);

has errmsg_too_long => (
    isa      => 'Str',
    is       => 'rw',
    required => 0,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->human_name .
          ' must be no more than ' .
          $self->max_length .
          ' characters long';
    },
);

sub _max_length {
    my ($self) = @_;

    return unless $self->max_length;

    if (length $self->value > $self->max_length) {
        $self->error($self->errmsg_too_long);
    }
    return $self;
}

after '_validate' => sub { return shift->_max_length };

1;



=pod

=head1 NAME

SparkX::Form::Field::Validator::MaxLength - Validates a variable does not exceed a given size

=head1 VERSION

version 0.2102

=head1 DESCRIPTION

A maximum length enforcement mix-in. Adds two fields plus action.
Makes sure that C<value> is at most C<max_length> characters long.

=head1 ACCESSORS

=head2 max_length => Int

The maximum length you desire. Required. In a subclass, you can:

 has '+max_length' => (required => 0,default => sub { $HOW_LONG });

if you want to have it optional with a default

=head2 errmsg_too_long => Str

Error message to be shown if C<value> is too long.



=head1 AUTHOR

  James Laver L<http://jameslaver.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by James Laver C<< <sprintf qw(%s@%s.%s cpan jameslaver com)> >>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__END__

