package MsgPack::RPC::Event::Write;
our $AUTHORITY = 'cpan:YANICK';
$MsgPack::RPC::Event::Write::VERSION = '2.0.3';
use Moose;

extends 'Beam::Event';

has payload => (
    is => 'ro',
    lazy => 1,
    default => sub {
        $_[0]->message->pack
    },
);

has message => (
    is => 'ro',
);

sub encoded {
    my $self = shift;
    
    MsgPack::Encoder->new(struct => $self->payload)->encoded;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::RPC::Event::Write

=head1 VERSION

version 2.0.3

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
