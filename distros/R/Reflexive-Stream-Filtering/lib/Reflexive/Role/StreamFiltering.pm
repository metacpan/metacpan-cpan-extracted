package Reflexive::Role::StreamFiltering;
{
  $Reflexive::Role::StreamFiltering::VERSION = '1.122150';
}

#ABSTRACT: Provides a composable behavior for Reflex::Streams to use POE::Filters
use Moose::Role;

requires qw/ on_data put emit /;

use POE::Filter::Stream;
use Reflexive::Event::Data;


has input_filter =>
(
    is => 'rw',
    isa => 'POE::Filter',
    default => sub { POE::Filter::Stream->new() },
    handles =>
    {
        'filter_get' => 'get_one',
        'filter_start' => 'get_one_start',
    }
);


has output_filter =>
(
    is => 'rw',
    isa => 'POE::Filter',
    default => sub { POE::Filter::Stream->new() },
    handles =>
    {
        'filter_put' => 'put',
    }
);


around on_data => sub
{
    my ($orig, $self, $args) = @_;

    $self->filter_start([$args->octets()]);
    while(1)
    {
        my $ret = $self->filter_get();
        if($#$ret == -1)
        {
            last;
        }
        else
        {
            for(0..$#$ret)
            {
                $self->emit
                (
                    -name => 'data',
                    -type => 'Reflexive::Event::Data',
                    data => $ret->[$_],
                );
            }
        }
    }
};


around put => sub
{
    my ($orig, $self, $arg) = @_;

    my $ret = $self->filter_put([$arg]);
    
    foreach my $item (@$ret)
    {
        $self->$orig($item);
    }
};

1;



=pod

=head1 NAME

Reflexive::Role::StreamFiltering - Provides a composable behavior for Reflex::Streams to use POE::Filters

=head1 VERSION

version 1.122150

=head1 DESCRIPTION

Reflexive::Role::StreamFiltering provides a composable behavior that takes and
uses a POE::Filter instance to filter inbound and outbound data similar to a
POE::Wheel object. But this class is much much simpler. The goal is to merely
shim in a POE::Filter instance and to do it as unobtrusively as possible.

=head1 PUBLIC_ATTRIBUTES

=head2 input_filter

    is: rw, isa: POE::Filter, default: POE::Filter::Stream

This attribute is mostly to be provided at construction of the Stream. If none
is provided then POE::Filter::Stream (which is just a passthrough) is used.

Internally, the following handles are provided:

    'filter_get' => 'get_one',
    'filter_start' => 'get_one_start',

Incidentially, only the newer POE::Filter get_one_start/get_one interace is
supported.

=head2 output_filter

    is: rw, isa: POE::Filter, default: POE::Filter::Stream

Like the input_filter attribute, this is to be provided at construction time of
the Stream. If an output_filter is not provided, POE::Filter::Stream is used.

The following handles are provided:

    'filter_put' => 'put'

=head1 PUBLIC_METHODS

=head2 put

    (Any)

This method is around advised to run the provided data through the filter before
passing it along to the original method if the filter returns multiple filtered
chunks then each chunk will get its own method call.

=head1 PROTECTED_METHODS

=head2 on_data

    (Reflexive::Event::Data)

on_data is the advised to intercept data events. Data is passed through the
ilter via get_one_start. Then get_one is called until no more filtered chunks
are returned. Each filtered chunk is then delievered via the emitted data event
which is reemitted.

=head1 CAVEATS

The filter attributes are marked as read-write, but take care when swapping
filters as the filters may have data left in their buffers. This module isn't
quite as smart as POE::Wheel::ReadWrite and it won't automagically pull any
buffered data out of the previous filter and apply it to the new filter.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
