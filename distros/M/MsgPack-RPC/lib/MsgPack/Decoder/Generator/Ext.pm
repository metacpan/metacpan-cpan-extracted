package MsgPack::Decoder::Generator::Ext;
our $AUTHORITY = 'cpan:YANICK';
$MsgPack::Decoder::Generator::Ext::VERSION = '2.0.3';
use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has size => ( required => 1,);

has '+bytes' => sub { 1 + $_[0]->size };

sub gen_value {
    my $self = shift;

    my $data = $self->buffer;

    my $type = ord substr $data, 0, 1, '';

    MsgPack::Type::Ext->new(
        fix  => 1,
        size => $self->size,
        data => $data,
        type => $type,
    );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::Decoder::Generator::Ext

=head1 VERSION

version 2.0.3

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
