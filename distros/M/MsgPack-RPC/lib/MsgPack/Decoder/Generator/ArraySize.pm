package MsgPack::Decoder::Generator::ArraySize;
our $AUTHORITY = 'cpan:YANICK';
$MsgPack::Decoder::Generator::ArraySize::VERSION = '2.0.3';
use Moose;
use MooseX::MungeHas 'is_ro';

use experimental 'signatures';

extends 'MsgPack::Decoder::Generator';

has is_map => sub { 0 };

has '+next' => sub($self) {
    return [[ 'Array', size => $self->buffer_as_int, is_map => $self->is_map ]];
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::Decoder::Generator::ArraySize

=head1 VERSION

version 2.0.3

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
