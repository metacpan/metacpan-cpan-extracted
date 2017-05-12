package MsgPack::Type::Ext;
our $AUTHORITY = 'cpan:YANICK';
$MsgPack::Type::Ext::VERSION = '1.0.1';
use strict;
use warnings;

use Moose;

has "type" => (
    isa => 'Int',
    is => 'ro',
    required => 1,
);

has "data" => (
    is => 'ro',
    required => 1,
);

has fix => (
    isa => 'Bool',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        length($self->data) < 16;
    },
);

has size => (
    isa => 'Int',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        if ( $self->fix ) {
            my $size = 0;
            $size++ while 2**$size < length $self->data;
            return 2**$size;
            
        }

        return length $self->data;
    },
);

sub padded_data {
    my $self = shift;

    my $size = $self->size;

    my $data = $self->data;
    return join '', ( chr(0) ) x ($size - length $data), $data;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::Type::Ext

=head1 VERSION

version 1.0.1

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
