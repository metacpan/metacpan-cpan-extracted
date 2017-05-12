package Storm::Role::Query::HasLimitClause;
{
  $Storm::Role::Query::HasLimitClause::VERSION = '0.240';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;
use MooseX::Types::Moose qw( ArrayRef );


use Storm::SQL::Fragment::Limit;

has '_limit' => (
    is => 'rw',
    isa => 'Maybe[Object]',
);

sub limit {
    my ( $self, $value ) = @_;
    my $map = $self->_attribute_map;
    

    my $element = Storm::SQL::Fragment::Limit->new($value);
    $self->_set_limit( $element );
    
    return $self;
}

sub _limit_clause {
    my ( $self ) = @_;
    return if ! $self->_limit;
    return $self->_limit->sql;
}



no Moose::Role;

1;


__END__

=pod

=head1 NAME

Storm::Role::Query::HasLimitClause - Role for queries with a LIMIT clause

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

Modified from code in Dave Rolsky's L<Fey> module.

=head1 COPYRIGHT

    Copyright (c) 2010 Jeffrey Ray Hallock. All rights reserved.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

