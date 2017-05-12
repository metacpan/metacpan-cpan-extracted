package TPath::Selector::Test::AnywhereMatch;
$TPath::Selector::Test::AnywhereMatch::VERSION = '1.007';
# ABSTRACT: handles C<//~foo~> expression

use Moose;
use TPath::Test::Node::Match;
use namespace::autoclean;


with 'TPath::Selector::Test::Match';

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;
    $class->$orig(
        %args,
        first_sensitive => 1,
        axis            => 'descendant',
    );
};

sub BUILD {
    my $self = shift;
    my $nt = TPath::Test::Node::Match->new( rx => $self->rx );
    $self->_node_test($nt);
}

sub to_string {
    my $self = shift;
    return
        '//'
      . ( $self->is_inverted ? '^' : '' )
      . $self->_stringify_match( $self->val );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Selector::Test::AnywhereMatch - handles C<//~foo~> expression

=head1 VERSION

version 1.007

=head1 ROLES

L<TPath::Selector::Test>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
