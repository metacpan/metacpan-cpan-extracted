package Storm::Role::Query::HasOrderByClause;
{
  $Storm::Role::Query::HasOrderByClause::VERSION = '0.240';
}

use Moose::Role;
use MooseX::Types::Moose qw( ArrayRef );

with 'Storm::Role::Query::HasAttributeMap';

use Storm::SQL::Fragment::OrderBy;

has '_order_by' => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
    traits => [qw( Array )],
    handles => {
        '_add_order_by_element' => 'push',
        'order_by_elements' => 'elements',
        '_has_no_order_by_elements' => 'is_empty',
    }
);

sub order_by {
    my ( $self, @args ) = @_;
    my $map = $self->_attribute_map;
    
    my ( $token, $order ) = @args;
    ( $token ) = $self->args_to_sql_objects( $token );

    my $element = Storm::SQL::Fragment::OrderBy->new($token, $order);
    $self->_add_order_by_element( $element );
    
    return $self;
}

sub _order_by_clause {
    my ( $self ) = @_;
    return if $self->_has_no_order_by_elements;
    
    my $sql = 'ORDER BY ';
    $sql .= join q[, ], map { $_->sql } $self->order_by_elements;
    
    return $sql;
}



no Moose::Role;

1;


__END__

=pod

=head1 NAME

Storm::Role::Query::HasOrderByClause - Role for queries with an ORDER BY clause

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

Modified from code in Dave Rolsky's L<Fey> module.

=head1 COPYRIGHT

    Copyright (c) 2010 Jeffrey Ray Hallock. All rights reserved.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

