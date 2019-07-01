package MsgPack::Decoder::Generator::Any;
our $AUTHORITY = 'cpan:YANICK';
$MsgPack::Decoder::Generator::Any::VERSION = '2.0.3';
use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

use experimental 'switch', 'signatures';

has '+bytes' => sub { 1 };

has '+next' => sub {
    my $self = shift;
    my $byte = $self->buffer_as_int;

    given( $byte ) {
        return [ [ 'FixInt', buffer => $self->buffer ] ]  
            when $byte <= 0x7f;

        return [ [ 'FixInt', negative => 1, buffer => $self->buffer ] ]
            when [ 0xe0 ... 0xff ];

        return [ [ 'Str', bytes => $byte - 0xa0 ] ] when [ 0xa0 ... 0xbf ];
        return SizedType( 2**($byte - 0xd9),  [ 'Str' ] )
            when [ 0xd9 ... 0xdb ];

        # binaries
        return SizedType( 2**($byte - 0xc4),  [ 'Str' ] )
            when [ 0xc4 ... 0xc6 ];

        return [[ 'Boolean', buffer => $self->buffer ]] when [ 0xc2 ... 0xc3 ];
        return [[ 'Nil' ]] when 0xc0 ;

        return [ [ 'Float', size => 4 * ( 2**($byte-0xca) ) ] ] when [ 0xca ... 0xcb ];

        return [ [ 'Int', size =>  2**($byte-0xd0)  ] ] when [ 0xd0 ... 0xd3 ];
        return [ [ 'UInt', size =>  2**($byte-0xcc)  ] ] when [ 0xcc ... 0xcf ];

        return [[ 'Array', size => $byte - 0x90  ]] when [ 0x90 ... 0x9f ];
        return SizedType( 2 * 2**($byte - 0xdc), 'Array' ) when [ 0xdc ... 0xdd ];

        return [[ 'Array', size => $byte - 0x80, is_map => 1 ]] when [ 0x80 ... 0x8f ];
        return SizedType( 2 * 2**($byte - 0xde), [ 'Array', is_map => 1 ] ) when [ 0xde ... 0xdf ];

        return SizedType( 2**($byte - 0xc7) => [ 'Ext' ] )
            when [ 0xc7 ... 0xc9 ];
        return [ [ 'Ext', size => 2**($byte-0xd4)] ] when  [ 0xd4 ... 0xd8 ];

        default { return [] }
    }
};

sub SizedType ( $size, $next ) {
    return [[ 'Size', bytes => $size, next_item => $next ]];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::Decoder::Generator::Any

=head1 VERSION

version 2.0.3

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
