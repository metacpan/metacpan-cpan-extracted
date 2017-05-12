package TPath::Predicate::Boolean;
$TPath::Predicate::Boolean::VERSION = '1.007';
# ABSTRACT: implements the C<[@foo or @bar ]> in C<//a/b[@foo or @bar]>


use Moose;
use TPath::TypeConstraints;


with 'TPath::Predicate';


has t => ( is => 'ro', does => 'TPath::Test', required => 1 );

sub filter {
    my ( $self, $c ) = @_;
    return grep { $self->t->test($_) } @$c;
}

sub to_string { $_[0]->t->to_string }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Predicate::Boolean - implements the C<[@foo or @bar ]> in C<//a/b[@foo or @bar]>

=head1 VERSION

version 1.007

=head1 DESCRIPTION

The object that selects the correct members of collection based on whether a boolean expression evaluated with
them as the context returns a true value.

=head1 ATTRIBUTES

=head2 t

The L<TPath::Test> evaluated by the predicate.

=head1 ROLES

L<TPath::Predicate>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
