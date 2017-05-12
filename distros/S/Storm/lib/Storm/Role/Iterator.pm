package Storm::Role::Iterator;
{
  $Storm::Role::Iterator::VERSION = '0.240';
}

use Moose::Role;
requires qw( _get_next_result reset);

has index => (
    is       => 'ro',
    isa      => 'Int',
    default  => 0,
    traits   => [qw/Counter/],
    init_arg => undef,
    handles => {
        '_increase_index' => 'inc'   ,
        '_reset_index'    => 'reset' ,
    },
);


sub next {
    my $self   = shift;
    my $result = $self->_get_next_result();
    
    return unless $result;

    # increase the index by one
    $self->_increase_index;

    return $result;
}

sub all {
    my $self = shift;
    $self->reset if $self->index;
    return $self->remaining;
}


sub remaining {
    my $self = shift;
    
    my @result;
    while ( my $object = $self->next ) {
        push @result, $object;
    }

    return @result;
}



no Moose::Role;
1;



__END__

=pod

=head1 NAME

Storm::Role::Iterator - Role for iterators

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

Modified from code in Dave Rolsky's L<Fey::ORM> module.

=head1 COPYRIGHT

    Copyright (c) 2010 Jeffrey Ray Hallock. All rights reserved.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut
