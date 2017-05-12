package TPath::TypeCheck;
$TPath::TypeCheck::VERSION = '1.007';
# ABSTRACT: applies type constraint on nodes


use Moose::Role;


has node_type =>
  ( isa => 'Maybe[Str]', is => 'ro', writer => '_node_type', default => undef );


sub _typecheck {
    my ( $self, $n ) = @_;
    return unless $self->node_type;
    confess 'can only handle nodes of type ' . $self->node_type
      unless $n->isa( $self->node_type );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::TypeCheck - applies type constraint on nodes

=head1 VERSION

version 1.007

=head1 DESCRIPTION

Role of an object that checks the class of a node against the class it knows it can handle.

=head1 METHODS

=head2 _typecheck

Expects a node. Confesses if the node is of the wrong type.

=head1 ATTRIBUTES

=over 8

=item node_type

If set on object construction, all nodes handled by the C<TPath::TypeCheck> will have 
to be of this class or an error will be thrown. Can be used to enforce type safety. 
The test is only performed on certain gateway methods -- C<TPath::Expression::select()> and 
C<TPath::Index::index()> -- so little overhead is incurred.

=back

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
