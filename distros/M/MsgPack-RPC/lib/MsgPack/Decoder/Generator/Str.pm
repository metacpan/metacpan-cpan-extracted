package MsgPack::Decoder::Generator::Str;
our $AUTHORITY = 'cpan:YANICK';
$MsgPack::Decoder::Generator::Str::VERSION = '2.0.3';
use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has '+bytes' => (
    trigger => sub {
        my ( $self, $value ) = @_;
        $self->push_decoded->('') unless $value;
    }
);

sub BUILDARGS {
    my( undef, %args ) = @_;
    $args{bytes} ||= $args{size} || 0;
    return \%args;
}

sub gen_value {
    my $self = shift;

    return $self->buffer;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::Decoder::Generator::Str

=head1 VERSION

version 2.0.3

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
