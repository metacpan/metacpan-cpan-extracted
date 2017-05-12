package TPath::Test::Node::Tag;
$TPath::Test::Node::Tag::VERSION = '1.007';
# ABSTRACT: L<TPath::Test::Node> implementing basic tag pattern; e.g., C<//foo>

use Moose;
use namespace::autoclean;


with 'TPath::Test::Node';


has tag => ( is => 'ro', isa => 'Str', required => 1 );

has _cr => ( is => 'rw', isa => 'CodeRef' );

# required by TPath::Test::Node
sub passes {

    # my ( $self, $ctx ) = @_;
    (
        $_[0]->_cr // $_[0]->_cr(
            do {
                my $f   = $_[1]->i->f;
                my $tag = $_[0]->tag;
                my $sr  = $f->can('has_tag');
                sub { $sr->( $f, $_[0], $tag ) };
              }
        )
    )->( $_[1][0] );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Test::Node::Tag - L<TPath::Test::Node> implementing basic tag pattern; e.g., C<//foo>

=head1 VERSION

version 1.007

=head1 ATTRIBUTES

=head2 tag

Tag or value to match.

=head1 ROLES

L<TPath::Test::Node>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
