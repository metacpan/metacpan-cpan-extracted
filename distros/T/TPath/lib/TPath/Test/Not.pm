package TPath::Test::Not;
$TPath::Test::Not::VERSION = '1.007';
# ABSTRACT: implements logical negation of a test


use Moose;
use TPath::Test;
use TPath::TypeConstraints;


with 'TPath::Test::Boolean';


has t => ( is => 'ro', isa => 'CondArg', required => 1 );

# required by TPath::Test
sub test {
    my ( $self, $ctx ) = @_;
    return $self->t->test($ctx) ? 0 : 1;
}

sub to_string {
    my $self = shift;
    return '!' . $self->t->to_string;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Test::Not - implements logical negation of a test

=head1 VERSION

version 1.007

=head1 DESCRIPTION

For use by compiled TPath expressions. Not for external consumption.

=head1 ATTRIBUTES

=head2 t

The single test the negation of which will provide the value of this L<TPath::Test>.

=head1 ROLES

L<TPath::Test::Boolean>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
