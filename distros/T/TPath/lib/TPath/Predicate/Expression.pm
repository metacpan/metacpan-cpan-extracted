package TPath::Predicate::Expression;
$TPath::Predicate::Expression::VERSION = '1.007';
# ABSTRACT: implements the C<[c]> in C<//a/b[c]>


use Moose;
use TPath::TypeConstraints;


with 'TPath::Predicate';


has e => ( is => 'ro', isa => 'TPath::Expression', required => 1 );

sub filter {
    my ( $self, $c ) = @_;
    return grep { $self->e->test($_) } @$c;
}

sub to_string {
    $_[0]->e->to_string;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Predicate::Expression - implements the C<[c]> in C<//a/b[c]>

=head1 VERSION

version 1.007

=head1 DESCRIPTION

The object that selects the correct members of collection based whether an expression evaluated with
them as the context selects a non-empty set of nodes.

=head1 ATTRIBUTES

=head2 e

The L<TPath::Expression> evaluated by the predicate.

=head1 ROLES

L<TPath::Predicate>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
