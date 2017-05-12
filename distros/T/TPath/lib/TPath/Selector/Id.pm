package TPath::Selector::Id;
$TPath::Selector::Id::VERSION = '1.007';
# ABSTRACT: C<TPath::Selector> that implements C<id(foo)>

use Moose;
use namespace::autoclean;


with 'TPath::Selector';

has id => ( isa => 'Str', is => 'ro', required => 1 );

# required by TPath::Selector
sub select {
    my ( $self, $ctx ) = @_;
    my $n = $ctx->i->indexed->{ $self->id };
    $ctx->bud($n) // ();
}

sub to_string {
    my $self = shift;
    return ':id(' . $self->_escape( $self->id, ')' ) . ')';
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Selector::Id - C<TPath::Selector> that implements C<id(foo)>

=head1 VERSION

version 1.007

=head1 ROLES

L<TPath::Selector>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
