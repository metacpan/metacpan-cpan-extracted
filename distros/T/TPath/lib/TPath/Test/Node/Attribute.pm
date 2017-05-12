package TPath::Test::Node::Attribute;
$TPath::Test::Node::Attribute::VERSION = '1.007';
# ABSTRACT: L<TPath::Test::Node> implementing attributes; e.g., C<//@foo>

use Moose;
use namespace::autoclean;


with 'TPath::Test::Node';


has a => ( is => 'ro', isa => 'TPath::Attribute', required => 1 );

has _cr => ( is => 'rw', isa => 'CodeRef' );

# required by TPath::Test::Node
sub passes {

    # my ( $self, $ctx ) = @_;
    return (
        $_[0]->_cr // do {
            my $a     = $_[0]->a;
            my $apply = $a->can('apply');
            $_[0]->_cr( sub { $apply->( $a, $_[0] ) ? 1 : undef } );
          }
    )->( $_[1] );
}

sub to_string { $_[0]->a->to_string }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Test::Node::Attribute - L<TPath::Test::Node> implementing attributes; e.g., C<//@foo>

=head1 VERSION

version 1.007

=head1 ATTRIBUTES

=head2 a

Attribute to detect.

=head1 ROLES

L<TPath::Test::Node>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
