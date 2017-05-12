package TPath::Selector::Test::AnywhereTag;
$TPath::Selector::Test::AnywhereTag::VERSION = '1.007';
# ABSTRACT: handles C<//foo> expression

use Moose;
use TPath::Test::Node::Tag;
use namespace::autoclean;


with 'TPath::Selector::Test';

has tag => ( is => 'ro', isa => 'Str', required => 1 );

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
    my $nt = TPath::Test::Node::Tag->new( tag => $self->tag );
    $self->_node_test($nt);
}

sub to_string {
    my $self = shift;
    return
        '//'
      . ( $self->is_inverted ? '^' : '' )
      . $self->_stringify_label( $self->tag );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Selector::Test::AnywhereTag - handles C<//foo> expression

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
