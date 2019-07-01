package MsgPack::Decoder::Event::Decoded;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: MsgPacker::Decoder decoding event 
$MsgPack::Decoder::Event::Decoded::VERSION = '2.0.3';

use Moose;
extends 'Beam::Event';

has payload => (
    is => 'ro',
    isa => 'ArrayRef',
    required => 1,
    traits => [ 'Array' ],
    handles => {
        payload_list => 'elements',
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::Decoder::Event::Decoded - MsgPacker::Decoder decoding event 

=head1 VERSION

version 2.0.3

=head1 DESCRIPTION 

Event emitted by a L<MsgPacker::Decoder> object configured as an emitter
when incoming data structured are decoded.

=head1 METHODS

=head2 payload_list 

Returns a list of all decoded data structures.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
