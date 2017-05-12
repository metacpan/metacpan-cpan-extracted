package TPath::Numifiable;
$TPath::Numifiable::VERSION = '1.007';
# ABSTRACT: role of things that evaluate to numbers

use Moose::Role;


with 'TPath::Stringifiable';


has negated => ( is => 'ro', isa => 'Bool', default => 0 );


requires 'to_num';

around to_num => sub {
    my ( $orig, $self, $ctx ) = @_;
    my $v = $self->$orig($ctx);
    return $self->negated ? -$v : $v;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Numifiable - role of things that evaluate to numbers

=head1 VERSION

version 1.007

=head1 ATTRIBUTES

=head2 negated

Whether the expressions is negated.

=head1 ROLES

L<TPath::Stringifiable>

=head1 REQUIRED METHODS

=head2 C<to_num($ctx)>

Takes a L<TPath::Context> and returns a number.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
