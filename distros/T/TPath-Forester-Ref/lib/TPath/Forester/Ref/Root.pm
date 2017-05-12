package TPath::Forester::Ref::Root;
{
  $TPath::Forester::Ref::Root::VERSION = '0.004';
}

# ABSTRACT: additional behavior for the root node of a struct tree


use v5.10;
use Moose::Role;
use namespace::autoclean;
use Scalar::Util qw(refaddr);

has _node_counts =>
  ( is => 'ro', isa => 'HashRef[HashRef]', default => sub { {} } );

# protects against cycles
sub _cycle_check {
    my ( $self, $node, $fetch ) = @_;
    return unless $node->is_ref;
    my $ra          = refaddr $node->value;
    my $node_counts = $self->_node_counts;
    my $props       = $node_counts->{$ra};
    return $props if $fetch;
    if ($props) {
        $props->{n}->_repeats(0);
        $node->_first(0);
        $node->_repeats( $props->{c} );
        $props->{c}++;
    }
    else {
        $node_counts->{$ra} = { n => $node, c => 1 };
    }
}

1;

__END__

=pod

=head1 NAME

TPath::Forester::Ref::Root - additional behavior for the root node of a struct tree

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Some additional behavior for the root node of a struct tree. In particular, the root
keeps track of cycles and repeated references.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
