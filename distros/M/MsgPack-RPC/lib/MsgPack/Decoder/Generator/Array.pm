package MsgPack::Decoder::Generator::Array;
our $AUTHORITY = 'cpan:YANICK';
$MsgPack::Decoder::Generator::Array::VERSION = '2.0.3';
use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has size => ( required => 1,);

has values => (
    isa => 'ArrayRef',
    lazy => 1,
    default => sub { [] },
    traits => [ 'Array' ],
    handles => {
        push_value => 'push',
        nbr_values => 'count',
    },
);

has '+bytes' => sub { 0 };

has is_map => sub { 0 };

has '+next' => sub {
    my $self = shift;

    my $size= $self->size;
    $size *= 2 if $self->is_map;

    unless( $size ) {
        $self->push_decoded->( $self->is_map ? {} : [] );
        return [];
    }

    my @array;

    my @next = ( ( ['Any', push_decoded => sub { 
        push @array, @_; 
        $self->push_decoded->( $self->is_map ? { @array } : \@array) if @array == $size;
    } ] ) x $size,
        [ 'Noop', push_decoded => $self->push_decoded  ] ); 

    return \@next;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::Decoder::Generator::Array

=head1 VERSION

version 2.0.3

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
